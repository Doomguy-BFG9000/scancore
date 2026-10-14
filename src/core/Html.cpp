#include "Html.h"

#include <lexbor/css/css.h>
#include <lexbor/html/html.h>
#include <lexbor/selectors/selectors.h>

#include <QHash>

#include <memory>

namespace sc {

namespace {

// lexbor parsers are not thread-safe, so each worker thread keeps its own
// parser, selector engine and a cache of compiled selector lists.
struct SelectorEngine {
    lxb_css_parser_t *parser = nullptr;
    lxb_css_selectors_t *cssSelectors = nullptr;
    lxb_selectors_t *selectors = nullptr;
    QHash<QString, lxb_css_selector_list_t *> lists;

    SelectorEngine() {
        parser = lxb_css_parser_create();
        lxb_css_parser_init(parser, nullptr);
        cssSelectors = lxb_css_selectors_create();
        lxb_css_selectors_init(cssSelectors);
        lxb_css_parser_selectors_set(parser, cssSelectors);
        selectors = lxb_selectors_create();
        lxb_selectors_init(selectors);
        lxb_selectors_opt_set(selectors, LXB_SELECTORS_OPT_MATCH_FIRST);
    }

    ~SelectorEngine() {
        // Every compiled list shares the parser's memory pool; freeing it
        // once releases all of them.
        for (auto *list : std::as_const(lists))
            if (list) {
                lxb_css_selector_list_destroy_memory(list);
                break;
            }
        lxb_selectors_destroy(selectors, true);
        lxb_css_selectors_destroy(cssSelectors, true);
        lxb_css_parser_destroy(parser, true);
    }

    lxb_css_selector_list_t *compile(const QString &css) {
        if (auto it = lists.constFind(css); it != lists.constEnd())
            return it.value();
        const auto utf8 = css.toUtf8();
        auto *list = lxb_css_selectors_parse(parser, reinterpret_cast<const lxb_char_t *>(utf8.constData()),
                                             size_t(utf8.size()));
        if (parser->status != LXB_STATUS_OK)
            list = nullptr;
        lists.insert(css, list);
        return list;
    }
};

SelectorEngine &engine() {
    thread_local SelectorEngine instance;
    return instance;
}

QString fromLxb(const lxb_char_t *data, size_t len) {
    return data ? QString::fromUtf8(reinterpret_cast<const char *>(data), qsizetype(len)) : QString();
}

lxb_status_t collect(lxb_dom_node_t *node, lxb_css_selector_specificity_t, void *ctx) {
    static_cast<QList<HtmlNode> *>(ctx)->append(HtmlNode(node));
    return LXB_STATUS_OK;
}

lxb_status_t matched(lxb_dom_node_t *, lxb_css_selector_specificity_t, void *ctx) {
    *static_cast<bool *>(ctx) = true;
    return LXB_STATUS_STOP;
}

lxb_status_t serializeCb(const lxb_char_t *data, size_t len, void *ctx) {
    static_cast<QByteArray *>(ctx)->append(reinterpret_cast<const char *>(data), qsizetype(len));
    return LXB_STATUS_OK;
}

} // namespace

bool HtmlNode::isElement() const { return m_node && m_node->type == LXB_DOM_NODE_TYPE_ELEMENT; }
bool HtmlNode::isText() const { return m_node && m_node->type == LXB_DOM_NODE_TYPE_TEXT; }

QString HtmlNode::tag() const {
    if (!isElement())
        return {};
    size_t len = 0;
    const auto *name = lxb_dom_element_local_name(lxb_dom_interface_element(m_node), &len);
    return fromLxb(name, len).toLower();
}

QString HtmlNode::attr(const char *name) const {
    if (!isElement())
        return {};
    size_t len = 0;
    const auto *value = lxb_dom_element_get_attribute(lxb_dom_interface_element(m_node),
                                                      reinterpret_cast<const lxb_char_t *>(name), strlen(name), &len);
    return fromLxb(value, len);
}

bool HtmlNode::hasAttr(const char *name) const {
    return isElement() && lxb_dom_element_has_attribute(lxb_dom_interface_element(m_node),
                                                        reinterpret_cast<const lxb_char_t *>(name), strlen(name));
}

QString HtmlNode::text() const {
    if (!m_node)
        return {};
    auto *node = m_node;
    // A document's textContent is null in the DOM; use its root element.
    if (node->type == LXB_DOM_NODE_TYPE_DOCUMENT) {
        auto *element = lxb_dom_document_element(lxb_dom_interface_document(node));
        if (!element)
            return {};
        node = lxb_dom_interface_node(element);
    }
    size_t len = 0;
    auto *data = lxb_dom_node_text_content(node, &len);
    auto result = fromLxb(data, len);
    if (data)
        lxb_dom_document_destroy_text(node->owner_document, data);
    return result;
}

QString HtmlNode::textTrim() const { return collapse(text()); }

QString HtmlNode::innerHtml() const {
    QByteArray out;
    if (!m_node)
        return {};
    for (auto *child = m_node->first_child; child; child = child->next)
        lxb_html_serialize_tree_cb(child, serializeCb, &out);
    return QString::fromUtf8(out);
}

QString HtmlNode::outerHtml() const {
    QByteArray out;
    if (m_node)
        lxb_html_serialize_tree_cb(m_node, serializeCb, &out);
    return QString::fromUtf8(out);
}

QList<HtmlNode> HtmlNode::select(const QString &css) const {
    QList<HtmlNode> nodes;
    if (!m_node)
        return nodes;
    auto &e = engine();
    auto *list = e.compile(css);
    if (!list)
        return nodes;
    lxb_selectors_find(e.selectors, m_node, list, collect, &nodes);
    return nodes;
}

HtmlNode HtmlNode::first(const QString &css) const {
    const auto nodes = select(css);
    return nodes.isEmpty() ? HtmlNode() : nodes.first();
}

bool HtmlNode::matches(const QString &css) const {
    if (!isElement())
        return false;
    auto &e = engine();
    auto *list = e.compile(css);
    if (!list)
        return false;
    bool found = false;
    lxb_selectors_match_node(e.selectors, m_node, list, matched, &found);
    return found;
}

HtmlNode HtmlNode::closest(const QString &css) const {
    for (auto node = *this; node; node = node.parent())
        if (node.matches(css))
            return node;
    return {};
}

QList<HtmlNode> HtmlNode::childNodes() const {
    QList<HtmlNode> nodes;
    if (m_node)
        for (auto *child = m_node->first_child; child; child = child->next)
            nodes.append(HtmlNode(child));
    return nodes;
}

HtmlNode HtmlNode::parent() const {
    if (!m_node || !m_node->parent || m_node->parent->type != LXB_DOM_NODE_TYPE_ELEMENT)
        return {};
    return HtmlNode(m_node->parent);
}

void HtmlNode::remove() {
    if (m_node)
        lxb_dom_node_remove(m_node);
}

HtmlDocument::HtmlDocument(const QByteArray &html) {
    m_doc = lxb_html_document_create();
    lxb_html_document_parse(m_doc, reinterpret_cast<const lxb_char_t *>(html.constData()), size_t(html.size()));
}

HtmlDocument::~HtmlDocument() {
    if (m_doc)
        lxb_html_document_destroy(m_doc);
}

HtmlNode HtmlDocument::root() const { return HtmlNode(lxb_dom_interface_node(m_doc)); }

HtmlNode HtmlDocument::body() const {
    auto *body = lxb_html_document_body_element(m_doc);
    return HtmlNode(body ? lxb_dom_interface_node(body) : nullptr);
}

QString resolveUrl(const QString &base, const QString &href) {
    const auto value = href.trimmed();
    if (value.isEmpty() || value.startsWith(QLatin1String("data:")) || value.startsWith(QLatin1String("javascript:")))
        return {};
    const auto url = QUrl(base).resolved(QUrl(value));
    if (!url.isValid() || (url.scheme() != QLatin1String("https") && url.scheme() != QLatin1String("http")))
        return {};
    return url.toString(QUrl::FullyEncoded);
}

QString collapse(const QString &text) { return text.simplified(); }

QString decodeEntities(const QString &text) {
    if (!text.contains(QLatin1Char('&')))
        return text.simplified();
    HtmlDocument doc(QStringLiteral("<span>%1</span>").arg(text));
    return doc.first(QStringLiteral("span")).textTrim();
}

} // namespace sc
