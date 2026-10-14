#pragma once

#include "core/Task.h"

#include <QObject>
#include <QQmlEngine>
#include <QVariantMap>

namespace sc {

// Optional link to a scancore.onl account. Signing in stores the site's
// session cookie in the app's cookie jar; the password is never saved.
// Sync brings the website library and comic reading history into the local
// library and adds local saves to the website when it knows the series.
class Account : public QObject {
    Q_OBJECT
    QML_ELEMENT
    QML_SINGLETON
    Q_PROPERTY(bool signedIn READ signedIn NOTIFY changed)
    Q_PROPERTY(QVariantMap user READ user NOTIFY changed)
    Q_PROPERTY(bool syncing READ syncing NOTIFY changed)
    Q_PROPERTY(QString lastSync READ lastSync NOTIFY changed)
    Q_PROPERTY(QString site READ site CONSTANT)

public:
    explicit Account(QObject *parent = nullptr);
    static Account *instance();
    static Account *create(QQmlEngine *, QJSEngine *) { return instance(); }

    bool signedIn() const { return !m_user.isEmpty(); }
    QVariantMap user() const { return m_user; }
    bool syncing() const { return m_syncing; }
    QString lastSync() const;
    QString site() const { return QStringLiteral("https://scancore.onl"); }

    Q_INVOKABLE sc::Task *signIn(const QString &email, const QString &password);
    Q_INVOKABLE void signOut();
    // {libraryImported, historyImported, pushed}
    Q_INVOKABLE sc::Task *sync();

signals:
    void changed();

private:
    void setUser(const QVariantMap &user);
    static QVariantMap importAll(const QJsonObject &session);

    QVariantMap m_user;
    bool m_syncing = false;
};

} // namespace sc
