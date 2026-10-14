import QtQuick
import QtQuick.Controls.Basic
import QtQuick.Window
import ScanCore

// Anime player. ReAnime streams are the provider's own player page, shown in
// an embedded browser; ScanCore reads its position for resume, auto-next and
// AniSkip intro skipping.
Rectangle {
    id: watch
    property var media: ({})
    property var episodes: []
    property int index: 0

    readonly property var episode: episodes[index] || ({})
    readonly property bool hasPrev: index > 0
    readonly property bool hasNext: index < episodes.length - 1
    readonly property var series: Anime.seriesFor(media)
    property var streamsTask: null
    property var skipTask: null
    property string currentUrl: ""
    property real position: 0
    property real duration: 0
    property real resumeAt: 0
    property bool sideOpen: width > 1100
    property bool ended: false

    readonly property var streams: streamsTask && streamsTask.ok ? streamsTask.result.streams : []
    readonly property var skips: skipTask && skipTask.ok ? skipTask.result : []
    readonly property var activeSkip: {
        for (const s of skips)
            if (position >= s.start && position < s.end - 1) return s
        return null
    }

    color: "#000000"
    focus: true

    function load(i) {
        saveProgress(true)
        index = i
        position = 0
        duration = 0
        ended = false
        skipTask = null
        const p = Library.progressMap(series.id)[episodes[i].key]
        resumeAt = p && !p.completed && p.position ? (p.position.seconds || 0) : 0
        currentUrl = ""
        streamsTask = Anime.streams(media.anilistId, episodes[i].number)
    }

    Component.onCompleted: load(index)
    Component.onDestruction: saveProgress(true)

    Connections {
        target: watch.streamsTask
        function onFinished(result) {
            if (result.streams.length > 0) watch.currentUrl = result.streams[0].url
        }
    }

    property real lastSaved: 0
    function saveProgress(force) {
        if (!series.id || !episode.key || duration <= 0) return
        if (!force && Date.now() - lastSaved < 5000) return
        lastSaved = Date.now()
        const percent = Math.min(1, position / duration)
        Library.recordProgress(series, { key: episode.key, title: episode.title, number: String(episode.number) },
                               { type: "video", seconds: position, duration: duration }, percent, percent > 0.9)
    }

    function onPlayerTime(seconds, total, status) {
        if (total > 0 && duration === 0) {
            duration = total
            skipTask = Anime.skipTimes(media.anilistId, episode.number, Math.round(total))
            if (resumeAt > 5 && resumeAt < total - 30 && seconds < resumeAt - 5) {
                player.seek(resumeAt)
                Router.toast("Resumed at " + formatTime(resumeAt))
            }
        }
        if (total > 0) duration = total
        position = seconds
        saveProgress(false)
        if (activeSkip && App.settings.autoSkip === true && (activeSkip.type === "op" || activeSkip.type === "mixed-op" || activeSkip.type === "recap"))
            player.seek(activeSkip.end)
        if ((status === "Ended" || (total > 0 && seconds >= total - 1)) && !ended) {
            ended = true
            saveProgress(true)
            if (App.settings.autoNext !== false && hasNext) nextCountdown.start()
        }
    }

    function formatTime(s) {
        s = Math.floor(s)
        const m = Math.floor(s / 60)
        return m + ":" + String(s % 60).padStart(2, "0")
    }

    function exit() {
        saveProgress(true)
        if (Window.window.visibility === Window.FullScreen) Window.window.showNormal()
        Router.back()
    }

    Keys.onPressed: (event) => {
        if (event.key === Qt.Key_Escape) {
            if (Window.window.visibility === Window.FullScreen) Window.window.showNormal()
            else exit()
            event.accepted = true
        } else if (event.key === Qt.Key_N && hasNext) { load(index + 1); event.accepted = true }
        else if (event.key === Qt.Key_P && hasPrev) { load(index - 1); event.accepted = true }
    }

    // ---------------------------------------------------------------- top
    Rectangle {
        id: bar
        width: parent.width
        height: 56
        color: "#0b0b0c"
        visible: Window.window.visibility !== Window.FullScreen
        Rectangle { anchors.bottom: parent.bottom; width: parent.width; height: 1; color: "#1d1d21" }
        Row {
            x: 12
            anchors.verticalCenter: parent.verticalCenter
            spacing: 10
            IconButton { iconName: "arrow-left"; iconColor: "white"; tip: "Close player (Esc)"; onClicked: watch.exit() }
            Column {
                anchors.verticalCenter: parent.verticalCenter
                Text {
                    text: watch.media.title || ""
                    color: "white"
                    font.family: Theme.fontSans
                    font.pixelSize: Theme.textMd
                    font.weight: Font.DemiBold
                    width: Math.min(implicitWidth, watch.width - 520)
                    elide: Text.ElideRight
                }
                Text {
                    text: "Episode " + (watch.episode.number || "") + (watch.episode.title && !String(watch.episode.title).startsWith("Episode") ? " · " + watch.episode.title : "")
                    color: "#a1a1aa"
                    font.family: Theme.fontSans
                    font.pixelSize: Theme.textSm
                    width: Math.min(implicitWidth, watch.width - 520)
                    elide: Text.ElideRight
                }
            }
        }
        Row {
            anchors.right: parent.right
            anchors.rightMargin: 12
            anchors.verticalCenter: parent.verticalCenter
            spacing: 6
            Repeater {
                model: watch.streams
                Chip {
                    required property var modelData
                    text: modelData.quality
                    selected: watch.currentUrl === modelData.url
                    onClicked: watch.currentUrl = modelData.url
                }
            }
            Item { width: 8; height: 1 }
            IconButton { iconName: "skip-back"; iconColor: "white"; enabled: watch.hasPrev; tip: "Previous episode (P)"; onClicked: watch.load(watch.index - 1) }
            IconButton { iconName: "skip-forward"; iconColor: "white"; enabled: watch.hasNext; tip: "Next episode (N)"; onClicked: watch.load(watch.index + 1) }
            IconButton { iconName: "list"; iconColor: "white"; active: watch.sideOpen; tip: "Episodes"; onClicked: watch.sideOpen = !watch.sideOpen }
        }
    }

    // ---------------------------------------------------------------- player
    Item {
        id: stage
        anchors.top: bar.visible ? bar.bottom : parent.top
        anchors.bottom: parent.bottom
        anchors.left: parent.left
        anchors.right: side.left

        Loader {
            id: player
            anchors.fill: parent
            active: App.webEngine && watch.currentUrl.length > 0
            source: App.platform === "android" ? "../components/WebPlayerMobile.qml" : "../components/WebPlayer.qml"
            onLoaded: item.url = Qt.binding(() => watch.currentUrl)
            function seek(seconds) { if (item) item.seek(seconds) }
            Connections {
                target: player.item
                function onTime(seconds, total, status) { watch.onPlayerTime(seconds, total, status) }
            }
        }

        Column {
            anchors.centerIn: parent
            spacing: 14
            visible: !player.active
            Spinner {
                anchors.horizontalCenter: parent.horizontalCenter
                visible: watch.streamsTask !== null && watch.streamsTask.loading
                size: 30
                color: "#a1a1aa"
            }
            Text {
                width: 440
                horizontalAlignment: Text.AlignHCenter
                wrapMode: Text.Wrap
                visible: text.length > 0
                text: !App.webEngine ? "This build of SCANCORE has no embedded browser, which the ReAnime player needs."
                    : watch.streamsTask && !watch.streamsTask.loading
                      ? (watch.streamsTask.ok ? (watch.streamsTask.result.message || "") : watch.streamsTask.error) : ""
                color: "#d4d4d8"
                font.family: Theme.fontSans
                font.pixelSize: Theme.textMd
            }
            ScButton {
                anchors.horizontalCenter: parent.horizontalCenter
                visible: watch.streamsTask !== null && !watch.streamsTask.loading && watch.streams.length === 0
                text: "Try again"
                iconName: "refresh-cw"
                onClicked: watch.load(watch.index)
            }
        }

        // AniSkip button
        ScButton {
            anchors.right: parent.right
            anchors.bottom: parent.bottom
            anchors.margins: 80
            visible: watch.activeSkip !== null && !(App.settings.autoSkip === true)
            opacity: visible ? 1 : 0
            Behavior on opacity { NumberAnimation { duration: Motion.normal } }
            variant: "primary"
            iconName: "skip-forward"
            text: watch.activeSkip ? (watch.activeSkip.type.indexOf("ed") >= 0 ? "Skip ending" : watch.activeSkip.type === "recap" ? "Skip recap" : "Skip intro") : ""
            onClicked: player.seek(watch.activeSkip.end)
        }

        // Up next
        Rectangle {
            anchors.right: parent.right
            anchors.bottom: parent.bottom
            anchors.margins: 40
            width: 320
            height: 96
            radius: Theme.radiusLg
            color: "#141416"
            border.width: 1
            border.color: "#2a2a30"
            visible: nextCountdown.running
            Column {
                anchors.fill: parent
                anchors.margins: 16
                spacing: 10
                Text {
                    text: "Next episode in " + Math.ceil(nextCountdown.remaining) + "s"
                    color: "white"
                    font.family: Theme.fontSans
                    font.pixelSize: Theme.textMd
                    font.weight: Font.DemiBold
                }
                Row {
                    spacing: 8
                    ScButton { compact: true; variant: "primary"; text: "Play now"; onClicked: { nextCountdown.stop(); watch.load(watch.index + 1) } }
                    ScButton { compact: true; text: "Cancel"; onClicked: nextCountdown.stop() }
                }
            }
        }
        Timer {
            id: nextCountdown
            property real remaining: 8
            interval: 100
            repeat: true
            onRunningChanged: if (running) remaining = 8
            onTriggered: {
                remaining -= 0.1
                if (remaining <= 0) {
                    stop()
                    if (watch.hasNext) watch.load(watch.index + 1)
                }
            }
        }
    }

    // ---------------------------------------------------------------- episodes
    Rectangle {
        id: side
        anchors.top: bar.visible ? bar.bottom : parent.top
        anchors.bottom: parent.bottom
        anchors.right: parent.right
        width: watch.sideOpen && Window.window.visibility !== Window.FullScreen ? 340 : 0
        color: "#0e0e10"
        clip: true
        Behavior on width { NumberAnimation { duration: Motion.slow; easing.type: Easing.BezierSpline; easing.bezierCurve: Motion.emphasized } }
        Rectangle { width: 1; height: parent.height; color: "#1d1d21" }

        ListView {
            id: episodeList
            anchors.fill: parent
            anchors.margins: 8
            width: 324
            clip: true
            model: watch.episodes
            currentIndex: watch.index
            ScrollBar.vertical: ScScrollBar {}
            Component.onCompleted: positionViewAtIndex(watch.index, ListView.Center)
            delegate: AbstractButton {
                id: row
                required property var modelData
                required property int index
                readonly property var state: { Library.revision; return Library.progressMap(watch.series.id)[modelData.key] || null }
                width: 324
                height: 64
                hoverEnabled: true
                onClicked: watch.load(index)
                background: Rectangle {
                    radius: Theme.radiusMd
                    color: row.index === watch.index ? "#222226" : row.hovered ? "#18181b" : "transparent"
                }
                contentItem: Row {
                    spacing: 10
                    leftPadding: 6
                    Item {
                        width: 92
                        height: 52
                        anchors.verticalCenter: parent.verticalCenter
                        Cover { anchors.fill: parent; radius: 6; source: row.modelData.image || ""; title: "EP " + row.modelData.number }
                        Rectangle {
                            visible: row.state !== null
                            anchors.bottom: parent.bottom
                            width: parent.width * (row.state ? (row.state.completed ? 1 : row.state.percent) : 0)
                            height: 3
                            color: "white"
                        }
                    }
                    Column {
                        anchors.verticalCenter: parent.verticalCenter
                        width: 200
                        Text {
                            width: parent.width
                            text: "Episode " + row.modelData.number
                            color: row.index === watch.index ? "white" : "#d4d4d8"
                            font.family: Theme.fontSans
                            font.pixelSize: Theme.textSm
                            font.weight: Font.DemiBold
                        }
                        Text {
                            width: parent.width
                            text: row.modelData.title
                            color: "#8b8b93"
                            font.family: Theme.fontSans
                            font.pixelSize: Theme.textXs + 1
                            elide: Text.ElideRight
                        }
                    }
                }
            }
        }
    }
}
