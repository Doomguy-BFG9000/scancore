#include "Parallel.h"

namespace sc {

QThreadPool &fanoutPool() {
    static QThreadPool *pool = [] {
        auto *p = new QThreadPool;
        // Source fan-out mostly waits on the network.
        p->setMaxThreadCount(24);
        p->setExpiryTimeout(60000);
        return p;
    }();
    return *pool;
}

} // namespace sc
