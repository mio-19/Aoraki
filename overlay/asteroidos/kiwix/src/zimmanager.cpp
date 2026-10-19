#include "zimmanager.h"
#include <zim/archive.h>
#include <zim/entry.h>
#include <zim/item.h>
#include <zim/blob.h>
#include <zim/suggestion.h>
#include <QDir>
#include <QFileInfo>
#include <QStandardPaths>
#include <QRegularExpression>
#include <QUrl>
#include <QDebug>

ZimManager::ZimManager(QObject *parent)
    : QObject(parent)
{
}

ZimManager::~ZimManager() = default;

void ZimManager::scanArchives()
{
    m_archives.clear();

    QStringList searchDirs = {
        QStringLiteral("/var/lib/kiwix"),
        QStandardPaths::writableLocation(QStandardPaths::GenericDataLocation) + QStringLiteral("/kiwix"),
        QStringLiteral("/home/ceres/.local/share/kiwix")
    };

    QSet<QString> seenFiles;

    for (const QString &dirPath : searchDirs) {
        QDir dir(dirPath);
        if (!dir.exists()) continue;

        const QFileInfoList files = dir.entryInfoList({QStringLiteral("*.zim")}, QDir::Files | QDir::Readable);
        for (const QFileInfo &info : files) {
            const QString absPath = info.canonicalFilePath();
            if (absPath.isEmpty() || seenFiles.contains(absPath)) continue;
            seenFiles.insert(absPath);

            QVariantMap item;
            item[QStringLiteral("filePath")] = absPath;
            item[QStringLiteral("fileName")] = info.fileName();
            
            // Format size in MB/GB
            qint64 bytes = info.size();
            if (bytes >= 1024 * 1024 * 1024) {
                item[QStringLiteral("sizeStr")] = QString::number(bytes / (1024.0 * 1024.0 * 1024.0), 'f', 1) + QStringLiteral(" GB");
            } else {
                item[QStringLiteral("sizeStr")] = QString::number(bytes / (1024.0 * 1024.0), 'f', 0) + QStringLiteral(" MB");
            }

            // Attempt to extract title from archive
            QString title = info.baseName();
            try {
                zim::Archive arc(absPath.toStdString());
                try {
                    title = QString::fromStdString(arc.getMetadata("Title"));
                } catch (...) {}
                item[QStringLiteral("articleCount")] = static_cast<int>(arc.getEntryCount());
            } catch (...) {
                item[QStringLiteral("articleCount")] = 0;
            }

            item[QStringLiteral("title")] = title;
            m_archives.append(item);
        }
    }

    emit archivesListChanged();

    // Auto-open first archive if not already loaded
    if (!m_archive && !m_archives.isEmpty()) {
        openArchive(m_archives.first().toMap()[QStringLiteral("filePath")].toString());
    }
}

bool ZimManager::openArchive(const QString &filePath)
{
    try {
        m_archive = std::make_unique<zim::Archive>(filePath.toStdString());
        try {
            m_searcher = std::make_unique<zim::SuggestionSearcher>(*m_archive);
        } catch (...) {
            m_searcher.reset();
        }

        m_archiveName = QFileInfo(filePath).baseName();
        try {
            m_archiveName = QString::fromStdString(m_archive->getMetadata("Title"));
        } catch (...) {}
        m_archiveArticleCount = static_cast<int>(m_archive->getEntryCount());

        m_history.clear();
        m_historyIndex = -1;

        emit archiveChanged();
        emit historyChanged();

        openMainArticle();
        return true;
    } catch (const std::exception &e) {
        qWarning() << "Failed to open ZIM archive:" << filePath << e.what();
        emit articleLoadError(QString::fromLocal8Bit(e.what()));
        return false;
    }
}

void ZimManager::openMainArticle()
{
    if (!m_archive) return;

    try {
        if (m_archive->hasMainEntry()) {
            loadArticleByPath(QString::fromStdString(m_archive->getMainEntry().getPath()), true);
            return;
        }
    } catch (...) {}

    // Fallbacks
    QStringList candidates = {
        QStringLiteral("A/index.html"),
        QStringLiteral("index.html"),
        QStringLiteral("main.html"),
        QStringLiteral("A/Main_Page.html"),
        QStringLiteral("Main_Page.html")
    };

    for (const QString &cand : candidates) {
        try {
            if (m_archive->hasEntryByPath(cand.toStdString())) {
                loadArticleByPath(cand, true);
                return;
            }
        } catch (...) {}
    }

    // If no main entry, try opening the very first user entry
    try {
        if (m_archive->getEntryCount() > 0) {
            loadArticleByPath(QString::fromStdString(m_archive->getEntryByTitle(0).getPath()), true);
        }
    } catch (...) {}
}

void ZimManager::openPath(const QString &path)
{
    if (!m_archive || path.isEmpty()) return;

    QString target = path;

    // Remove URL scheme or anchor
    if (target.startsWith(QStringLiteral("zim://"))) {
        target = target.mid(6);
    }
    int hashIdx = target.indexOf('#');
    if (hashIdx >= 0) {
        target = target.left(hashIdx);
    }

    if (target.isEmpty()) return;

    // Resolve relative path against current path if needed
    if (!target.startsWith(QStringLiteral("/")) && !target.startsWith(QStringLiteral("A/")) && !m_currentPath.isEmpty()) {
        int lastSlash = m_currentPath.lastIndexOf('/');
        if (lastSlash >= 0) {
            QString base = m_currentPath.left(lastSlash + 1);
            QString resolved = QDir::cleanPath(base + target);
            if (m_archive->hasEntryByPath(resolved.toStdString())) {
                target = resolved;
            }
        }
    }

    loadArticleByPath(target, true);
}

void ZimManager::loadArticleByPath(const QString &path, bool recordHistory)
{
    if (!m_archive) return;

    try {
        std::string stdPath = path.toStdString();
        if (!m_archive->hasEntryByPath(stdPath)) {
            // Try fallback namespace prefixes
            if (!path.startsWith(QLatin1String("A/")) && m_archive->hasEntryByPath(("A/" + stdPath))) {
                stdPath = "A/" + stdPath;
            } else if (path.startsWith(QLatin1String("A/")) && m_archive->hasEntryByPath(stdPath.substr(2))) {
                stdPath = stdPath.substr(2);
            } else {
                emit articleLoadError(QStringLiteral("Article not found: ") + path);
                return;
            }
        }

        zim::Entry entry = m_archive->getEntryByPath(stdPath);
        zim::Item item = entry.getItem(true);
        zim::Blob data = item.getData();
        QByteArray rawData(data.data(), static_cast<int>(data.size()));

        m_currentPath = QString::fromStdString(item.getPath());
        m_currentTitle = QString::fromStdString(item.getTitle());
        m_currentHtml = cleanHtmlForWearable(QString::fromUtf8(rawData), m_currentPath);

        if (recordHistory) {
            // Trim forward history
            if (m_historyIndex >= 0 && m_historyIndex + 1 < m_history.size()) {
                m_history = m_history.mid(0, m_historyIndex + 1);
            }
            m_history.append(m_currentPath);
            m_historyIndex = m_history.size() - 1;
            emit historyChanged();
        }

        emit currentArticleChanged();
    } catch (const std::exception &e) {
        qWarning() << "Error reading ZIM entry:" << e.what();
        emit articleLoadError(QString::fromLocal8Bit(e.what()));
    }
}

QByteArray ZimManager::getEntryData(const QString &path)
{
    if (!m_archive || path.isEmpty()) return QByteArray();

    try {
        std::string stdPath = path.toStdString();
        if (m_archive->hasEntryByPath(stdPath)) {
            zim::Entry entry = m_archive->getEntryByPath(stdPath);
            zim::Item item = entry.getItem(true);
            zim::Blob blob = item.getData();
            return QByteArray(blob.data(), static_cast<int>(blob.size()));
        }
    } catch (...) {}

    return QByteArray();
}

QString ZimManager::cleanHtmlForWearable(const QString &rawHtml, const QString &articlePath)
{
    QString html = rawHtml;

    // Strip scripts, styles, metadata
    html.remove(QRegularExpression(QStringLiteral("<script[^>]*>[\\s\\S]*?<\\/script>"), QRegularExpression::CaseInsensitiveOption));
    html.remove(QRegularExpression(QStringLiteral("<style[^>]*>[\\s\\S]*?<\\/style>"), QRegularExpression::CaseInsensitiveOption));
    html.remove(QRegularExpression(QStringLiteral("<link[^>]*>"), QRegularExpression::CaseInsensitiveOption));

    // Determine base directory of current article for relative asset resolution
    QString baseDir;
    int lastSlash = articlePath.lastIndexOf('/');
    if (lastSlash >= 0) {
        baseDir = articlePath.left(lastSlash + 1);
    }

    // Rewrite image src to image://zim/...
    QRegularExpression imgRegex(QStringLiteral("<img([^>]*?)src=[\"']([^\"']+)[\"']([^>]*)>"), QRegularExpression::CaseInsensitiveOption);
    html.replace(imgRegex, QStringLiteral("<img\\1src=\"image://zim/\\2\"\\3>"));

    // Style HTML with AMOLED smartwatch readability (high contrast white on black, clean margins)
    QString styledHtml = QStringLiteral(
        "<html><head><style>"
        "body { color: #FFFFFF; background-color: #000000; font-family: sans-serif; font-size: 15px; line-height: 1.4; margin: 4px; }"
        "h1 { color: #00A3E0; font-size: 20px; margin-top: 10px; margin-bottom: 6px; font-weight: bold; }"
        "h2 { color: #33B5E5; font-size: 18px; margin-top: 10px; margin-bottom: 4px; }"
        "h3 { color: #80D0FF; font-size: 16px; margin-top: 8px; margin-bottom: 4px; }"
        "a { color: #4FC3F7; text-decoration: underline; font-weight: bold; }"
        "p { margin-bottom: 8px; }"
        "ul, ol { margin-left: 16px; margin-bottom: 8px; }"
        "li { margin-bottom: 4px; }"
        "table { width: 100%; border-collapse: collapse; margin-bottom: 8px; }"
        "th, td { border: 1px solid #444444; padding: 4px; font-size: 13px; }"
        "th { background-color: #1E1E24; color: #00A3E0; }"
        "img { max-width: 90%; height: auto; display: block; margin: 6px auto; border-radius: 4px; }"
        "</style></head><body>"
    );

    styledHtml += html;
    styledHtml += QStringLiteral("</body></html>");

    return styledHtml;
}

void ZimManager::search(const QString &query)
{
    m_searchResults.clear();
    const QString trimmed = query.trimmed();

    if (!m_archive || !m_searcher || trimmed.isEmpty()) {
        emit searchResultsChanged();
        return;
    }

    m_isSearching = true;
    emit isSearchingChanged();

    try {
        zim::SuggestionSearch searchObj = m_searcher->suggest(trimmed.toStdString());
        zim::SuggestionResultSet results = searchObj.getResults(0, 20);

        for (auto it = results.begin(); it != results.end(); ++it) {
            QVariantMap item;
            item[QStringLiteral("title")] = QString::fromStdString(it->getTitle());
            item[QStringLiteral("path")] = QString::fromStdString(it->getPath());
            if (it->hasSnippet()) {
                item[QStringLiteral("snippet")] = QString::fromStdString(it->getSnippet());
            } else {
                item[QStringLiteral("snippet")] = QString();
            }
            m_searchResults.append(item);
        }
    } catch (const std::exception &e) {
        qWarning() << "ZIM suggestion search failed:" << e.what();
    }

    m_isSearching = false;
    emit isSearchingChanged();
    emit searchResultsChanged();
}

void ZimManager::goBack()
{
    if (canGoBack()) {
        m_historyIndex--;
        emit historyChanged();
        loadArticleByPath(m_history.at(m_historyIndex), false);
    }
}

void ZimManager::goForward()
{
    if (canGoForward()) {
        m_historyIndex++;
        emit historyChanged();
        loadArticleByPath(m_history.at(m_historyIndex), false);
    }
}
