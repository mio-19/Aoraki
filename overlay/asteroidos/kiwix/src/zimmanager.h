#ifndef ZIMMANAGER_H
#define ZIMMANAGER_H

#include <QObject>
#include <QString>
#include <QVariantList>
#include <QByteArray>
#include <QStringList>
#include <memory>
#include <vector>

namespace zim {
    class Archive;
    class SuggestionSearcher;
}

class ZimManager : public QObject
{
    Q_OBJECT

    Q_PROPERTY(QString currentTitle READ currentTitle NOTIFY currentArticleChanged)
    Q_PROPERTY(QString currentHtml READ currentHtml NOTIFY currentArticleChanged)
    Q_PROPERTY(QString currentPath READ currentPath NOTIFY currentArticleChanged)
    Q_PROPERTY(bool hasOpenArchive READ hasOpenArchive NOTIFY archiveChanged)
    Q_PROPERTY(QString archiveName READ archiveName NOTIFY archiveChanged)
    Q_PROPERTY(int archiveArticleCount READ archiveArticleCount NOTIFY archiveChanged)
    Q_PROPERTY(bool canGoBack READ canGoBack NOTIFY historyChanged)
    Q_PROPERTY(bool canGoForward READ canGoForward NOTIFY historyChanged)
    Q_PROPERTY(QVariantList archives READ archives NOTIFY archivesListChanged)
    Q_PROPERTY(QVariantList searchResults READ searchResults NOTIFY searchResultsChanged)
    Q_PROPERTY(bool isSearching READ isSearching NOTIFY isSearchingChanged)

public:
    explicit ZimManager(QObject *parent = nullptr);
    ~ZimManager() override;

    QString currentTitle() const { return m_currentTitle; }
    QString currentHtml() const { return m_currentHtml; }
    QString currentPath() const { return m_currentPath; }
    bool hasOpenArchive() const { return m_archive != nullptr; }
    QString archiveName() const { return m_archiveName; }
    int archiveArticleCount() const { return m_archiveArticleCount; }
    bool canGoBack() const { return m_historyIndex > 0; }
    bool canGoForward() const { return m_historyIndex + 1 < m_history.size(); }
    QVariantList archives() const { return m_archives; }
    QVariantList searchResults() const { return m_searchResults; }
    bool isSearching() const { return m_isSearching; }

    Q_INVOKABLE void scanArchives();
    Q_INVOKABLE bool openArchive(const QString &filePath);
    Q_INVOKABLE void openPath(const QString &path);
    Q_INVOKABLE void openMainArticle();
    Q_INVOKABLE void search(const QString &query);
    Q_INVOKABLE void goBack();
    Q_INVOKABLE void goForward();

    QByteArray getEntryData(const QString &path);

signals:
    void currentArticleChanged();
    void archiveChanged();
    void historyChanged();
    void archivesListChanged();
    void searchResultsChanged();
    void isSearchingChanged();
    void articleLoadError(const QString &error);

private:
    void loadArticleByPath(const QString &path, bool recordHistory = true);
    QString cleanHtmlForWearable(const QString &rawHtml, const QString &articlePath);

    std::unique_ptr<zim::Archive> m_archive;
    std::unique_ptr<zim::SuggestionSearcher> m_searcher;

    QString m_currentTitle;
    QString m_currentHtml;
    QString m_currentPath;
    QString m_archiveName;
    int m_archiveArticleCount = 0;

    QStringList m_history;
    int m_historyIndex = -1;

    QVariantList m_archives;
    QVariantList m_searchResults;
    bool m_isSearching = false;
};

#endif // ZIMMANAGER_H
