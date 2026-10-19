#include "webclient.h"
#include <QNetworkRequest>
#include <QRegularExpression>
#include <QFile>
#include <QFileInfo>
#include <QUrlQuery>
#include <QDebug>

WebClient::WebClient(QObject *parent)
    : QObject(parent)
    , m_nam(new QNetworkAccessManager(this))
{
    m_nam->setRedirectPolicy(QNetworkRequest::NoLessSafeRedirectPolicy);
}

WebClient::~WebClient()
{
    stop();
}

void WebClient::setUrl(const QUrl &newUrl)
{
    if (m_currentUrl != newUrl) {
        load(newUrl.toString());
    }
}

void WebClient::load(const QString &target)
{
    QString trimmed = target.trimmed();
    if (trimmed.isEmpty()) return;

    QUrl requestUrl;
    if (trimmed.startsWith(QStringLiteral("file://")) || trimmed.startsWith(QStringLiteral("/"))) {
        requestUrl = QUrl::fromLocalFile(trimmed.startsWith(QStringLiteral("file://")) ? trimmed.mid(7) : trimmed);
    } else if (trimmed.contains(QStringLiteral("://"))) {
        requestUrl = QUrl(trimmed);
    } else if (trimmed.contains('.') && !trimmed.contains(' ')) {
        requestUrl = QUrl(QStringLiteral("https://") + trimmed);
    } else {
        search(trimmed);
        return;
    }

    startRequest(requestUrl, true);
}

void WebClient::search(const QString &query)
{
    QString trimmed = query.trimmed();
    if (trimmed.isEmpty()) return;

    QUrl searchUrl(QStringLiteral("https://html.duckduckgo.com/html/"));
    QUrlQuery q;
    q.addQueryItem(QStringLiteral("q"), trimmed);
    searchUrl.setQuery(q);

    startRequest(searchUrl, true);
}

void WebClient::reload()
{
    if (m_currentUrl.isValid()) {
        startRequest(m_currentUrl, false);
    }
}

void WebClient::stop()
{
    if (m_currentReply) {
        m_currentReply->abort();
        m_currentReply->deleteLater();
        m_currentReply = nullptr;
    }
    if (m_loading) {
        m_loading = false;
        emit loadingChanged();
    }
}

void WebClient::goBack()
{
    if (canGoBack()) {
        m_historyIndex--;
        emit historyChanged();
        startRequest(QUrl(m_history.at(m_historyIndex)), false);
    }
}

void WebClient::goForward()
{
    if (canGoForward()) {
        m_historyIndex++;
        emit historyChanged();
        startRequest(QUrl(m_history.at(m_historyIndex)), false);
    }
}

void WebClient::startRequest(const QUrl &requestUrl, bool recordHistory)
{
    stop();

    m_currentUrl = requestUrl;
    emit urlChanged();

    m_loading = true;
    m_loadProgress = 10;
    emit loadingChanged();
    emit loadProgressChanged();

    if (requestUrl.isLocalFile()) {
        QFile file(requestUrl.toLocalFile());
        if (file.open(QIODevice::ReadOnly)) {
            QString content = QString::fromUtf8(file.readAll());
            m_title = QFileInfo(file).baseName();
            m_html = processHtmlForWearable(content, requestUrl);
            emit titleChanged();
            emit htmlChanged();
        } else {
            m_html = QStringLiteral("<p style='color:#FF5252;'>Failed to load local file.</p>");
            emit htmlChanged();
            emit errorOccurred(QStringLiteral("Failed to open local file"));
        }
        m_loadProgress = 100;
        m_loading = false;
        emit loadProgressChanged();
        emit loadingChanged();

        if (recordHistory) {
            if (m_historyIndex >= 0 && m_historyIndex + 1 < m_history.size()) {
                m_history = m_history.mid(0, m_historyIndex + 1);
            }
            m_history.append(requestUrl.toString());
            m_historyIndex = m_history.size() - 1;
            emit historyChanged();
        }
        return;
    }

    QNetworkRequest request(requestUrl);
    request.setHeader(QNetworkRequest::UserAgentHeader,
                      QStringLiteral("Mozilla/5.0 (Linux; AsteroidOS; Smartwatch) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/120.0.0.0 Mobile Safari/537.36"));
    request.setRawHeader("Accept", "text/html,application/xhtml+xml,application/xml;q=0.9,*/*;q=0.8");
    request.setRawHeader("Accept-Language", "en-US,en;q=0.9");

    m_currentReply = m_nam->get(request);
    connect(m_currentReply, &QNetworkReply::downloadProgress, this, &WebClient::onDownloadProgress);
    connect(m_currentReply, &QNetworkReply::finished, this, &WebClient::onReplyFinished);

    if (recordHistory) {
        if (m_historyIndex >= 0 && m_historyIndex + 1 < m_history.size()) {
            m_history = m_history.mid(0, m_historyIndex + 1);
        }
        m_history.append(requestUrl.toString());
        m_historyIndex = m_history.size() - 1;
        emit historyChanged();
    }
}

void WebClient::onDownloadProgress(qint64 bytesReceived, qint64 bytesTotal)
{
    if (bytesTotal > 0) {
        m_loadProgress = qBound(10, static_cast<int>((bytesReceived * 100) / bytesTotal), 95);
    } else {
        m_loadProgress = qMin(m_loadProgress + 10, 85);
    }
    emit loadProgressChanged();
}

void WebClient::onReplyFinished()
{
    if (!m_currentReply) return;

    if (m_currentReply->error() == QNetworkReply::NoError) {
        QByteArray data = m_currentReply->readAll();
        QString content = QString::fromUtf8(data);

        // Update URL to redirect target if available
        QUrl redirectUrl = m_currentReply->attribute(QNetworkRequest::RedirectionTargetAttribute).toUrl();
        if (redirectUrl.isValid()) {
            QUrl resolved = m_currentUrl.resolved(redirectUrl);
            m_currentUrl = resolved;
            emit urlChanged();
        }

        m_html = processHtmlForWearable(content, m_currentUrl);
        emit htmlChanged();
        emit titleChanged();
    } else if (m_currentReply->error() != QNetworkReply::OperationCanceledError) {
        QString err = m_currentReply->errorString();
        m_html = QStringLiteral("<div style='text-align:center; padding:20px;'><h2 style='color:#FF5252;'>Page Load Failed</h2><p style='color:#CCCCCC;'>")
                 + err.toHtmlEscaped()
                 + QStringLiteral("</p></div>");
        emit htmlChanged();
        emit errorOccurred(err);
    }

    m_currentReply->deleteLater();
    m_currentReply = nullptr;

    m_loadProgress = 100;
    m_loading = false;
    emit loadProgressChanged();
    emit loadingChanged();
}

QString WebClient::processHtmlForWearable(const QString &rawHtml, const QUrl &baseUrl)
{
    QString html = rawHtml;

    // Extract title
    QRegularExpression titleRegex(QStringLiteral("<title[^>]*>([\\s\\S]*?)<\\/title>"), QRegularExpression::CaseInsensitiveOption);
    auto titleMatch = titleRegex.match(html);
    if (titleMatch.hasMatch()) {
        m_title = titleMatch.captured(1).trimmed();
    } else {
        m_title = baseUrl.host();
    }

    // Strip scripts and embedded interactive objects
    html.remove(QRegularExpression(QStringLiteral("<script[^>]*>[\\s\\S]*?<\\/script>"), QRegularExpression::CaseInsensitiveOption));
    html.remove(QRegularExpression(QStringLiteral("<style[^>]*>[\\s\\S]*?<\\/style>"), QRegularExpression::CaseInsensitiveOption));
    html.remove(QRegularExpression(QStringLiteral("<iframe[^>]*>[\\s\\S]*?<\\/iframe>"), QRegularExpression::CaseInsensitiveOption));

    // Resolve relative hyperlinks to absolute URLs against baseUrl
    QString resolvedHtml;
    resolvedHtml.reserve(html.size() + 1024);
    QRegularExpression linkRegex(QStringLiteral("<a([^>]*?)href=[\"']([^\"']+)[\"']([^>]*)>"), QRegularExpression::CaseInsensitiveOption);
    auto it = linkRegex.globalMatch(html);
    int lastPos = 0;
    while (it.hasNext()) {
        auto match = it.next();
        resolvedHtml.append(html.mid(lastPos, match.capturedStart() - lastPos));
        QString prefix = match.captured(1);
        QString href = match.captured(2);
        QString suffix = match.captured(3);

        if (!href.startsWith(QStringLiteral("http://")) &&
            !href.startsWith(QStringLiteral("https://")) &&
            !href.startsWith(QStringLiteral("file://")) &&
            !href.startsWith(QStringLiteral("mailto:")) &&
            !href.startsWith(QStringLiteral("tel:"))) {
            QUrl resolved = baseUrl.resolved(QUrl(href));
            href = resolved.toString();
        }
        resolvedHtml.append(QStringLiteral("<a") + prefix + QStringLiteral("href=\"") + href + QStringLiteral("\"") + suffix + QStringLiteral(">"));
        lastPos = match.capturedEnd();
    }
    resolvedHtml.append(html.mid(lastPos));
    html = resolvedHtml;

    // Style HTML with AMOLED smartwatch readability (high contrast white on black, cyan links, clean typography)
    QString styledHtml = QStringLiteral(
        "<html><head><style>"
        "body { color: #FFFFFF; background-color: #000000; font-family: sans-serif; font-size: 15px; line-height: 1.45; margin: 4px; }"
        "h1 { color: #00E5FF; font-size: 20px; margin-top: 10px; margin-bottom: 6px; font-weight: bold; }"
        "h2 { color: #33B5E5; font-size: 18px; margin-top: 10px; margin-bottom: 4px; }"
        "h3 { color: #80D0FF; font-size: 16px; margin-top: 8px; margin-bottom: 4px; }"
        "a { color: #00E5FF; text-decoration: underline; font-weight: bold; }"
        "p { margin-bottom: 8px; }"
        "ul, ol { margin-left: 16px; margin-bottom: 8px; }"
        "li { margin-bottom: 4px; }"
        "table { width: 100%; border-collapse: collapse; margin-bottom: 8px; }"
        "th, td { border: 1px solid #444444; padding: 4px; font-size: 13px; }"
        "th { background-color: #1A1A24; color: #00E5FF; }"
        "img { max-width: 90%; height: auto; display: block; margin: 6px auto; border-radius: 4px; }"
        "hr { border: none; border-top: 1px solid #333333; margin: 12px 0; }"
        "</style></head><body>"
    );

    styledHtml += html;
    styledHtml += QStringLiteral("</body></html>");

    return styledHtml;
}
