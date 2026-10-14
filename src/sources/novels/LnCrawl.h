#pragma once

#include "NovelSource.h"

namespace sc::novels {

// Paths of the optional lightnovel-crawler pack, installed by the
// Extensions service into the app data folder.
struct LnCrawlRuntime {
    static QString root();
    static QString python();
    static QString vendor();
    static QString bridge();
    static bool installed();
};

// One lightnovel-crawler adapter. Each operation starts the bundled Python
// with bridge.py; the bridge asks for every page it needs over stdout and
// SCANCORE fetches it with its own HTTP client, then reads the result.
class LnCrawlSource : public Source {
public:
    LnCrawlSource(SourceConfig config, QJsonObject entry) : Source(std::move(config)), m_entry(std::move(entry)) {}
    QList<Book> search(const QString &query) override;
    Book book(const QString &url, QList<ChapterRef> &chapters) override;
    QList<Block> chapter(const QString &url, QString &title) override;

private:
    QJsonObject run(QJsonObject request, int timeoutMs);
    QJsonObject m_entry;
};

} // namespace sc::novels
