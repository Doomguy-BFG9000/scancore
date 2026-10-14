#pragma once

#include "ComicSource.h"

#include <QList>

#include <memory>

namespace sc::comics {

// The comic sources built from the current manifest. Lookups return shared
// pointers so a manifest refresh can swap the set while requests run.
class Registry {
public:
    static void rebuild();
    static QList<std::shared_ptr<Source>> all();
    static std::shared_ptr<Source> byKey(const QString &key);
    static std::shared_ptr<Source> forUrl(const QString &url);
};

} // namespace sc::comics
