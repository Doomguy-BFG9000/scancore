import QtQuick
import QtWebView
import ScanCore

// Phone version of WebPlayer: same wrapper page and getTime/seek polling,
// hosted in the system WebView.
Item {
    id: root
    property string url
    signal time(real seconds, real total, string status)

    function seek(seconds) {
        web.runJavaScript("window.scSeek && window.scSeek(" + Number(seconds) + ")")
    }

    function wrapper(src) {
        const safe = String(src).replace(/"/g, "&quot;").replace(/</g, "&lt;")
        return "<!doctype html><html><head><meta charset='utf-8'><meta name='viewport' content='width=device-width,initial-scale=1'>"
            + "<style>html,body{margin:0;height:100%;background:#000;overflow:hidden}iframe{border:0;width:100%;height:100%}</style>"
            + "</head><body><iframe id='f' src=\"" + safe + "\" allow='autoplay; fullscreen; encrypted-media' allowfullscreen referrerpolicy='origin'></iframe>"
            + "<script>"
            + "window.__sc={t:0,d:0,s:''};var f=document.getElementById('f');"
            + "addEventListener('message',function(e){if(e.source!==f.contentWindow)return;var x=e.data;"
            + "if(typeof x==='string'){try{x=JSON.parse(x)}catch(_){return}}if(!x)return;"
            + "if(x.currentTime!==undefined){__sc.t=+x.currentTime||0;__sc.d=+x.duration||0}"
            + "if(x.playerStatus)__sc.s=String(x.playerStatus)});"
            + "setInterval(function(){try{f.contentWindow.postMessage({command:'getTime'},'*')}catch(_){}},1000);"
            + "window.scSeek=function(v){f.contentWindow.postMessage({command:'seek',value:v},'*')};"
            + "</script></body></html>"
    }

    onUrlChanged: if (url) web.loadHtml(wrapper(url), "https://reanime.to/")

    WebView {
        id: web
        anchors.fill: parent
    }

    Timer {
        interval: 1000
        running: root.visible
        repeat: true
        onTriggered: web.runJavaScript("JSON.stringify(window.__sc||{})", (result) => {
            try {
                const s = JSON.parse(result)
                if (s.d > 0) root.time(s.t, s.d, s.s || "")
            } catch (e) {}
        })
    }
}
