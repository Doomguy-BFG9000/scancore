#include "Cookies.h"

#include <QDateTime>
#include <QFile>
#include <QNetworkCookie>
#include <QSaveFile>

namespace sc {

QObject *CookieJar::owner() {
    static QObject object;
    return &object;
}

CookieJar &CookieJar::shared() {
    static CookieJar *jar = [] {
        auto *created = new CookieJar(owner());
        return created;
    }();
    return *jar;
}

QList<QNetworkCookie> CookieJar::cookiesForUrl(const QUrl &url) const {
    std::lock_guard lock(m_mutex);
    return QNetworkCookieJar::cookiesForUrl(url);
}

bool CookieJar::setCookiesFromUrl(const QList<QNetworkCookie> &cookies, const QUrl &url) {
    std::lock_guard lock(m_mutex);
    return QNetworkCookieJar::setCookiesFromUrl(cookies, url);
}

bool CookieJar::insertCookie(const QNetworkCookie &cookie) {
    std::lock_guard lock(m_mutex);
    return QNetworkCookieJar::insertCookie(cookie);
}

bool CookieJar::deleteCookie(const QNetworkCookie &cookie) {
    std::lock_guard lock(m_mutex);
    return QNetworkCookieJar::deleteCookie(cookie);
}

void CookieJar::load(const QString &path) {
    std::lock_guard lock(m_mutex);
    m_path = path;
    QFile file(path);
    if (!file.open(QIODevice::ReadOnly))
        return;
    QList<QNetworkCookie> cookies;
    const auto now = QDateTime::currentDateTimeUtc();
    while (!file.atEnd()) {
        const auto line = file.readLine().trimmed();
        if (line.isEmpty())
            continue;
        for (const auto &cookie : QNetworkCookie::parseCookies(line))
            if (!cookie.isSessionCookie() && cookie.expirationDate() > now)
                cookies.append(cookie);
    }
    setAllCookies(cookies);
}

void CookieJar::save() const {
    std::lock_guard lock(m_mutex);
    if (m_path.isEmpty())
        return;
    QSaveFile file(m_path);
    if (!file.open(QIODevice::WriteOnly))
        return;
    for (const auto &cookie : allCookies())
        if (!cookie.isSessionCookie())
            file.write(cookie.toRawForm(QNetworkCookie::Full) + '\n');
    file.commit();
}

} // namespace sc
