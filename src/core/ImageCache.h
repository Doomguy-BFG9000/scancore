#pragma once

#include <QByteArray>
#include <QString>

namespace sc {

// Disk cache for remote images (covers and chapter pages), keyed by URL.
// Trimmed to a size budget on startup, least recently used first.
class ImageCache {
public:
    static void init(const QString &dir, qint64 budgetBytes);
    // Blocking; returns the image bytes from disk or the network.
    static QByteArray fetch(const QString &url, const QString &referer);
    static void setBudget(qint64 bytes);
    static qint64 sizeOnDisk();
    static void clear();
    static void trim();
};

} // namespace sc
