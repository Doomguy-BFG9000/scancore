#pragma once

#include "Http.h"

#include <QList>
#include <QThreadPool>
#include <QtConcurrent/QtConcurrentRun>

#include <functional>
#include <optional>

namespace sc {

QThreadPool &fanoutPool();

template <typename T>
struct Outcome {
    std::optional<T> value;
    QString error;
    int status = 0;
    QString verifyUrl;
    bool ok() const { return value.has_value(); }
};

// Runs jobs concurrently on the fan-out pool and waits for all of them. The
// caller's cancel flag is carried into every job, so cancelling a search
// stops all of its source requests.
template <typename T>
QList<Outcome<T>> parallel(const QList<std::function<T()>> &jobs) {
    const auto cancel = CancelScope::current();
    QList<QFuture<Outcome<T>>> futures;
    futures.reserve(jobs.size());
    for (const auto &job : jobs) {
        futures.append(QtConcurrent::run(&fanoutPool(), [job, cancel]() -> Outcome<T> {
            CancelScope scope(cancel);
            Outcome<T> outcome;
            try {
                outcome.value = job();
            } catch (const Error &e) {
                outcome.error = e.message();
                outcome.status = e.status();
                outcome.verifyUrl = e.verifyUrl();
            } catch (const std::exception &e) {
                outcome.error = QString::fromUtf8(e.what());
            }
            return outcome;
        }));
    }
    QList<Outcome<T>> results;
    results.reserve(futures.size());
    for (auto &future : futures)
        results.append(future.result());
    return results;
}

} // namespace sc
