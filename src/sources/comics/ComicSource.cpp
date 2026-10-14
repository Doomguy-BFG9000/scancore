#include "ComicSource.h"

#include "Engines.h"

#include <QRegularExpression>

#include <algorithm>

namespace sc::comics {

QVariantMap Summary::toMap() const {
    return {{"title", title}, {"url", url},       {"cover", cover},   {"type", type},
            {"author", author}, {"genres", genres}, {"views", views}, {"source", source}};
}

QVariantMap Chapter::toMap() const {
    return {{"number", number}, {"title", title}, {"url", url},
            {"thumbnail", thumbnail}, {"slug", slug}, {"released", released}};
}

QVariantMap LatestItem::toMap() const {
    return {{"source", source},           {"sourceLabel", sourceLabel},   {"title", title},
            {"url", url},                 {"cover", cover},               {"chapterNumber", chapterNumber},
            {"chapterTitle", chapterTitle}, {"chapterUrl", chapterUrl}, {"publishedAt", publishedAt}};
}

bool Source::owns(const QUrl &url) const {
    const auto host = url.host().toLower();
    return std::any_of(m_config.hosts.begin(), m_config.hosts.end(),
                       [&](const QString &allowed) { return hostMatches(host, allowed); });
}

Headers Source::jsonHeaders() const {
    return {{"Accept", "application/json, text/plain, */*"},
            {"Origin", m_config.base.toUtf8()},
            {"Referer", (m_config.base + QLatin1Char('/')).toUtf8()}};
}

Headers Source::htmlHeaders() const {
    return {{"Accept", "text/html,application/xhtml+xml,application/xml;q=0.9,*/*;q=0.8"},
            {"Accept-Language", "en-US,en;q=0.9"},
            {"Referer", (m_config.base + QLatin1Char('/')).toUtf8()}};
}

std::unique_ptr<Source> createSource(const SourceConfig &config) {
    const auto &e = config.engine;
    if (e == QLatin1String("asura"))
        return std::make_unique<AsuraSource>(config);
    if (e == QLatin1String("webtoon"))
        return std::make_unique<WebtoonSource>(config);
    if (e == QLatin1String("mangadex"))
        return std::make_unique<MangaDexSource>(config);
    if (e == QLatin1String("flame"))
        return std::make_unique<FlameSource>(config);
    if (e == QLatin1String("hive"))
        return std::make_unique<HiveSource>(config);
    if (e == QLatin1String("iken"))
        return std::make_unique<IkenSource>(config);
    if (e == QLatin1String("qimanga"))
        return std::make_unique<QiMangaSource>(config);
    if (e == QLatin1String("madara"))
        return std::make_unique<MadaraSource>(config);
    if (e == QLatin1String("wp"))
        return std::make_unique<WpSource>(config);
    return nullptr;
}

QString str(const QJsonValue &value) {
    if (value.isString())
        return value.toString();
    if (value.isDouble()) {
        const double d = value.toDouble();
        if (d == double(qint64(d)))
            return QString::number(qint64(d));
        return QString::number(d);
    }
    if (value.isBool())
        return value.toBool() ? QStringLiteral("true") : QStringLiteral("false");
    return {};
}

QString chapterNumberFrom(const QString &text) {
    static const QRegularExpression labelled(QStringLiteral(R"((?:chapter|ch\.?|episode|ep\.?)\s*([\d.]+))"),
                                             QRegularExpression::CaseInsensitiveOption);
    static const QRegularExpression bare(QStringLiteral(R"(([\d]+(?:\.\d+)?))"));
    if (auto m = labelled.match(text); m.hasMatch())
        return m.captured(1);
    if (auto m = bare.match(text); m.hasMatch())
        return m.captured(1);
    return QStringLiteral("0");
}

void sortChapters(QList<Chapter> &chapters) {
    std::stable_sort(chapters.begin(), chapters.end(),
                     [](const Chapter &a, const Chapter &b) { return a.number.toDouble() < b.number.toDouble(); });
}

QString pathSegment(const QUrl &url, int index) {
    const auto parts = url.path().split(QLatin1Char('/'), Qt::SkipEmptyParts);
    if (index < 0)
        index += int(parts.size());
    return index >= 0 && index < parts.size() ? parts.at(index) : QString();
}

} // namespace sc::comics
