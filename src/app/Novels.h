#pragma once

#include "core/Task.h"

#include <QObject>
#include <QQmlEngine>

namespace sc {

class Novels : public QObject {
    Q_OBJECT
    QML_ELEMENT
    QML_SINGLETON

public:
    explicit Novels(QObject *parent = nullptr) : QObject(parent) {}

    Q_INVOKABLE QVariantList sources() const;
    Q_INVOKABLE QString seriesId(const QString &url) const;

    // {shelves: [{title, books}]}
    Q_INVOKABLE sc::Task *discover();
    // {books, providers}
    Q_INVOKABLE sc::Task *search(const QString &query, const QString &source = QStringLiteral("all"));
    // {series, chapters, offline}
    Q_INVOKABLE sc::Task *book(const QString &url, const QVariantMap &summary = {});
    // {title, blocks: [{kind, text, html}], offline}
    Q_INVOKABLE sc::Task *chapter(const QString &chapterUrl, const QString &seriesId = QString());

    static QVariantList fetchUnits(const QString &url);
    static QVariantMap fetchChapter(const QString &chapterUrl);
};

} // namespace sc
