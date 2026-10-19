#ifndef WEBCLIENT_H
#define WEBCLIENT_H

#include <QObject>
#include <QUrl>
#include <QString>
#include <QStringList>
#include <QNetworkAccessManager>
#include <QNetworkReply>

class WebClient : public QObject
{
    Q_OBJECT

    Q_PROPERTY(QUrl url READ url WRITE setUrl NOTIFY urlChanged)
    Q_PROPERTY(QString title READ title NOTIFY titleChanged)
    Q_PROPERTY(QString html READ html NOTIFY htmlChanged)
    Q_PROPERTY(bool loading READ loading NOTIFY loadingChanged)
    Q_PROPERTY(int loadProgress READ loadProgress NOTIFY loadProgressChanged)
    Q_PROPERTY(bool canGoBack READ canGoBack NOTIFY historyChanged)
    Q_PROPERTY(bool canGoForward READ canGoForward NOTIFY historyChanged)

public:
    explicit WebClient(QObject *parent = nullptr);
    ~WebClient() override;

    QUrl url() const { return m_currentUrl; }
    void setUrl(const QUrl &newUrl);

    QString title() const { return m_title; }
    QString html() const { return m_html; }
    bool loading() const { return m_loading; }
    int loadProgress() const { return m_loadProgress; }
    bool canGoBack() const { return m_historyIndex > 0; }
    bool canGoForward() const { return m_historyIndex + 1 < m_history.size(); }

    Q_INVOKABLE void load(const QString &target);
    Q_INVOKABLE void reload();
    Q_INVOKABLE void stop();
    Q_INVOKABLE void goBack();
    Q_INVOKABLE void goForward();
    Q_INVOKABLE void search(const QString &query);

signals:
    void urlChanged();
    void titleChanged();
    void htmlChanged();
    void loadingChanged();
    void loadProgressChanged();
    void historyChanged();
    void errorOccurred(const QString &errorString);

private slots:
    void onReplyFinished();
    void onDownloadProgress(qint64 bytesReceived, qint64 bytesTotal);

private:
    void startRequest(const QUrl &requestUrl, bool recordHistory = true);
    QString processHtmlForWearable(const QString &rawHtml, const QUrl &baseUrl);

    QNetworkAccessManager *m_nam;
    QNetworkReply *m_currentReply = nullptr;

    QUrl m_currentUrl;
    QString m_title;
    QString m_html;
    bool m_loading = false;
    int m_loadProgress = 0;

    QStringList m_history;
    int m_historyIndex = -1;
};

#endif // WEBCLIENT_H
