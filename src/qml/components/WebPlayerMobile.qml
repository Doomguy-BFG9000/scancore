import QtQuick
import QtWebView
import ScanCore

// Phone version of WebPlayer: same wrapper page and getTime/seek messages,
// hosted in the system WebView.
//
// The page reports back through its title, never through runJavaScript
// callbacks: on Android, Qt WebView runs those callbacks on the Android UI
// thread, alongside the QML engine on Qt's own thread, which crashes the app
// (a SIGSEGV in the JavaScript engine, often right after a tap). Title
// changes arrive as a signal, which Qt queues onto its own thread.
Item {
    id: root
    property string url
    signal time(real seconds, real total, string status)
    // The video was tapped. Taps inside the cross-origin player never reach
    // the wrapper, but the first tap moves focus into the frame and blurs the
    // wrapper's window; handing focus back re-arms that for the next tap.
    signal interacted()
    property int taps: 0

    // No callback: see above.
    function seek(seconds) {
        web.runJavaScript("window.scSeek && window.scSeek(" + Number(seconds) + ")")
    }

    function wrapper(src) {
        const safe = String(src).replace(/"/g, "&quot;").replace(/</g, "&lt;")
        return "<!doctype html><html><head><meta charset='utf-8'><meta name='viewport' content='width=device-width,initial-scale=1'>"
            + "<style>html,body{margin:0;height:100%;background:#000;overflow:hidden}iframe{border:0;width:100%;height:100%}</style>"
            + "</head><body><iframe id='f' src=\"" + safe + "\" allow='autoplay; fullscreen; encrypted-media' allowfullscreen referrerpolicy='origin'></iframe>"
            + "<script>"
            + "window.__sc={t:0,d:0,s:'',taps:0};var f=document.getElementById('f');"
            + "function pub(){var v='sc:'+JSON.stringify(__sc);if(document.title!==v)document.title=v}"
            + "addEventListener('message',function(e){if(e.source!==f.contentWindow)return;var x=e.data;"
            + "if(typeof x==='string'){try{x=JSON.parse(x)}catch(_){return}}if(!x)return;"
            + "if(x.currentTime!==undefined){__sc.t=+x.currentTime||0;__sc.d=+x.duration||0}"
            + "if(x.playerStatus)__sc.s=String(x.playerStatus);pub()});"
            + "setInterval(function(){try{f.contentWindow.postMessage({command:'getTime'},'*')}catch(_){}},1000);"
            + "window.scSeek=function(v){f.contentWindow.postMessage({command:'seek',value:v},'*')};"
            + "addEventListener('blur',function(){__sc.taps++;pub();setTimeout(function(){try{document.activeElement.blur();window.focus()}catch(_){}},200)});"
            + "</script></body></html>"
    }

    onUrlChanged: {
        taps = 0
        if (url) web.loadHtml(wrapper(url), "https://reanime.to/")
    }

    WebView {
        id: web
        anchors.fill: parent
        onTitleChanged: {
            const title = String(web.title)
            if (!title.startsWith("sc:")) return
            try {
                const s = JSON.parse(title.slice(3))
                if (s.taps > root.taps) {
                    root.taps = s.taps
                    root.interacted()
                }
                if (s.d > 0) root.time(s.t, s.d, s.s || "")
            } catch (e) {}
        }
    }
}
