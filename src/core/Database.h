#pragma once

#include <QString>
#include <QVariant>
#include <QVariantList>
#include <QVariantMap>

#include <functional>
#include <optional>

namespace sc {

// Local SQLite store: library, progress, history, preferences, downloads and
// a key/value cache for metadata. Every thread gets its own connection; WAL
// lets readers and the single writer work at the same time.
class Database {
public:
    static void open(const QString &path);
    static QString path();

    // Runs one statement. SELECTs return rows as maps keyed by column name.
    static QVariantList query(const QString &sql, const QVariantList &binds = {});
    static QVariantMap one(const QString &sql, const QVariantList &binds = {});
    static QVariant scalar(const QString &sql, const QVariantList &binds = {});
    static void exec(const QString &sql, const QVariantList &binds = {});
    static void transaction(const std::function<void()> &work);

    // Cached JSON/text values with an expiry, used for metadata that is slow
    // to fetch (AniList pages, chapter lists, manifests).
    static std::optional<QByteArray> cacheGet(const QString &key, bool allowStale = false);
    static void cachePut(const QString &key, const QByteArray &value, qint64 ttlSeconds);
    static void cachePrune();

    static QVariant pref(const QString &key, const QVariant &fallback = {});
    static void setPref(const QString &key, const QVariant &value);

    static qint64 now();
};

} // namespace sc
