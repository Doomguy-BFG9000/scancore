import QtQuick
import QtQuick.Controls.Basic
import ScanCore

// A titled horizontal row of covers with smooth arrow and wheel scrolling.
Column {
    id: shelf
    property string title
    property string subtitle
    property var items: []
    property bool loading: false
    property string error: ""
    property int cardWidth: Theme.compact ? 118 : 156
    property real coverRatio: 1.5
    property string actionText: ""
    property var subtitleFor: (item) => ""
    property var badgeFor: (item) => ""
    property var progressFor: (item) => -1
    signal action()
    signal retry()
    signal opened(var item, Item coverItem)

    spacing: 14
    width: parent ? parent.width : 800
    visible: loading || error.length > 0 || items.length > 0

    Item {
        width: parent.width
        height: 30
        Row {
            anchors.left: parent.left
            anchors.leftMargin: Theme.gutter
            anchors.verticalCenter: parent.verticalCenter
            spacing: 10
            Text {
                text: shelf.title
                color: Theme.text
                font.family: Theme.fontDisplay
                font.pixelSize: Theme.textXl
                font.weight: Font.DemiBold
                anchors.verticalCenter: parent.verticalCenter
            }
            Text {
                visible: shelf.subtitle.length > 0
                text: shelf.subtitle
                color: Theme.textFaint
                font.family: Theme.fontSans
                font.pixelSize: Theme.textSm
                anchors.verticalCenter: parent.verticalCenter
                anchors.verticalCenterOffset: 2
            }
        }
        Row {
            anchors.right: parent.right
            anchors.rightMargin: Theme.gutter - 6
            anchors.verticalCenter: parent.verticalCenter
            spacing: 4
            ScButton {
                visible: shelf.actionText.length > 0
                text: shelf.actionText
                variant: "ghost"
                compact: true
                onClicked: shelf.action()
            }
            IconButton {
                iconName: "chevron-left"
                enabled: list.contentX > 1
                onClicked: list.scrollBy(-list.width * 0.8)
            }
            IconButton {
                iconName: "chevron-right"
                enabled: list.contentX < list.contentWidth - list.width - 1
                onClicked: list.scrollBy(list.width * 0.8)
            }
        }
    }

    Item {
        width: parent.width
        height: shelf.cardWidth * shelf.coverRatio + 84

        ListView {
            id: list
            anchors.fill: parent
            visible: !shelf.loading && shelf.error.length === 0
            orientation: ListView.Horizontal
            leftMargin: Theme.gutter
            rightMargin: Theme.gutter
            spacing: 18
            clip: true
            model: shelf.items
            boundsBehavior: Flickable.StopAtBounds
            flickDeceleration: 4000
            reuseItems: true
            cacheBuffer: 600

            function scrollBy(delta) {
                const target = Math.max(-leftMargin, Math.min(contentWidth - width + rightMargin + originX, contentX + delta))
                scroller.to = target
                scroller.restart()
            }
            NumberAnimation {
                id: scroller
                target: list
                property: "contentX"
                duration: Motion.slow + 120
                easing.type: Easing.BezierSpline
                easing.bezierCurve: Motion.emphasized
            }
            WheelHandler {
                acceptedDevices: PointerDevice.Mouse
                onWheel: (event) => {
                    const delta = event.angleDelta.x !== 0 ? -event.angleDelta.x : -event.angleDelta.y
                    if (Math.abs(event.angleDelta.x) < Math.abs(event.angleDelta.y) && !(event.modifiers & Qt.ShiftModifier)) {
                        event.accepted = false
                        return
                    }
                    list.scrollBy(delta * 1.4)
                }
            }

            delegate: CoverCard {
                required property var modelData
                required property int index
                width: shelf.cardWidth
                height: list.height
                item: modelData
                index: index
                coverRatio: shelf.coverRatio
                subtitle: shelf.subtitleFor(modelData)
                badge: shelf.badgeFor(modelData)
                progress: shelf.progressFor(modelData)
                onOpened: (it, cover) => shelf.opened(it, cover)
            }
        }

        Row {
            visible: shelf.loading
            x: Theme.gutter
            spacing: 18
            Repeater {
                model: 8
                Column {
                    spacing: 10
                    Shimmer { width: shelf.cardWidth; height: shelf.cardWidth * shelf.coverRatio }
                    Shimmer { width: shelf.cardWidth * 0.8; height: 12; radius: 6 }
                    Shimmer { width: shelf.cardWidth * 0.5; height: 10; radius: 5 }
                }
            }
        }

        StateView {
            anchors.fill: parent
            anchors.leftMargin: Theme.gutter
            anchors.rightMargin: Theme.gutter
            visible: !shelf.loading && shelf.error.length > 0
            error: shelf.error
            compact: true
            onRetry: shelf.retry()
        }
    }
}
