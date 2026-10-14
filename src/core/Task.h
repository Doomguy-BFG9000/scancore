#pragma once

#include "Http.h"

#include <QObject>
#include <QPointer>
#include <QQmlEngine>
#include <QtQml/qqmlregistration.h>
#include <QVariant>

#include <functional>

namespace sc {

// One background operation exposed to QML. Services return a Task; pages bind
// to loading/error/result. The work runs on the shared pool and observes the
// task's cancel flag, which is set when QML drops the task or calls cancel().
class Task : public QObject {
    Q_OBJECT
    QML_ELEMENT
    QML_UNCREATABLE("Tasks are returned by services")
    Q_PROPERTY(bool loading READ loading NOTIFY changed)
    Q_PROPERTY(bool done READ done NOTIFY changed)
    Q_PROPERTY(bool ok READ ok NOTIFY changed)
    Q_PROPERTY(QString error READ error NOTIFY changed)
    Q_PROPERTY(int status READ status NOTIFY changed)
    Q_PROPERTY(QVariant result READ result NOTIFY changed)
    Q_PROPERTY(QString verifyUrl READ verifyUrl NOTIFY changed)

public:
    using Work = std::function<QVariant()>;

    // Starts `work` on the background pool. The task is owned by QML's
    // garbage collector once returned to it.
    static Task *run(Work work);
    // A task that has already finished with `value`.
    static Task *resolved(const QVariant &value);

    ~Task() override;

    bool loading() const { return m_loading; }
    bool done() const { return !m_loading; }
    bool ok() const { return !m_loading && m_error.isEmpty(); }
    QString error() const { return m_error; }
    int status() const { return m_status; }
    QVariant result() const { return m_result; }
    QString verifyUrl() const { return m_verifyUrl; }

    Q_INVOKABLE void cancel();
    // Calls fn(result) on success, now if already finished.
    void then(QObject *context, std::function<void(const QVariant &)> fn);

signals:
    void changed();
    void finished(const QVariant &result);
    void failed(const QString &error);

private:
    explicit Task(QObject *parent = nullptr);
    void complete(const QVariant &value, const QString &error, int status, const QString &verifyUrl = QString());

    bool m_loading = true;
    QString m_error;
    int m_status = 0;
    QVariant m_result;
    QString m_verifyUrl;
    CancelFlag m_cancel;
};

// Runs work on the background pool without a Task (fire and forget).
void runInBackground(std::function<void()> work);

} // namespace sc
