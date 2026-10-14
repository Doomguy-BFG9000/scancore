#pragma once

#include <QByteArray>
#include <QList>
#include <QString>
#include <QUrl>

struct lxb_dom_node;
struct lxb_html_document;

namespace sc {

// Thin wrapper over a lexbor DOM node. Nodes are only valid while their
// HtmlDocument is alive.
class HtmlNode {
public:
    HtmlNode() = default;
    explicit HtmlNode(lxb_dom_node *node) : m_node(node) {}

    bool isNull() const { return m_node == nullptr; }
    explicit operator bool() const { return m_node != nullptr; }
    bool isElement() const;
    bool isText() const;

    QString tag() const;
    QString attr(const char *name) const;
    bool hasAttr(const char *name) const;
    // Raw textContent.
    QString text() const;
    // textContent with whitespace collapsed and trimmed.
    QString textTrim() const;
    QString innerHtml() const;
    QString outerHtml() const;

    QList<HtmlNode> select(const QString &css) const;
    HtmlNode first(const QString &css) const;
    bool matches(const QString &css) const;
    HtmlNode closest(const QString &css) const;

    QList<HtmlNode> childNodes() const;
    HtmlNode parent() const;
    void remove();

    lxb_dom_node *raw() const { return m_node; }

private:
    lxb_dom_node *m_node = nullptr;
};

class HtmlDocument {
public:
    explicit HtmlDocument(const QByteArray &html);
    explicit HtmlDocument(const QString &html) : HtmlDocument(html.toUtf8()) {}
    ~HtmlDocument();
    HtmlDocument(const HtmlDocument &) = delete;
    HtmlDocument &operator=(const HtmlDocument &) = delete;

    HtmlNode root() const;
    HtmlNode body() const;
    QList<HtmlNode> select(const QString &css) const { return root().select(css); }
    HtmlNode first(const QString &css) const { return root().first(css); }

private:
    lxb_html_document *m_doc = nullptr;
};

// Resolves an href/src against a base, returning an empty string for
// unusable values (empty, javascript:, data:).
QString resolveUrl(const QString &base, const QString &href);
QString collapse(const QString &text);
// Decodes HTML entities in a fragment of text.
QString decodeEntities(const QString &text);

} // namespace sc
