#pragma once

#include "NovelSource.h"

namespace sc::novels {

class Registry {
public:
    static void rebuild();
    static QList<std::shared_ptr<Source>> all();
    static std::shared_ptr<Source> byKey(const QString &key);
    static std::shared_ptr<Source> forUrl(const QString &url);
};

} // namespace sc::novels
