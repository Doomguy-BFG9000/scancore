#pragma once

#include <QJsonObject>
#include <QString>

namespace sc {

// sources/manifest.json: source domains, availability and template options.
// The copy built into the app is the floor; a newer copy published in the
// GitHub repository replaces it at runtime so a domain change or a broken
// site does not need a new release. It holds data only, never code.
class Manifest {
public:
    static constexpr const char *RemoteUrl =
        "https://raw.githubusercontent.com/medium-gh/scancore/main/sources/manifest.json";

    static void load(const QString &cachePath);
    static QJsonObject current();
    static int version();

    // Fetches the published manifest; returns true when a newer one was
    // applied. Runs on a worker thread.
    static bool refresh();
    // Loads a manifest directly (tools and tests).
    static bool loadData(const QByteArray &json) { return apply(json, false); }

private:
    static bool apply(const QByteArray &json, bool persist);
};

} // namespace sc
