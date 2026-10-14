import QtQuick
import QtQuick.Effects
import ScanCore

// Rounded cover art. Shows a soft placeholder while loading, then fades and
// settles the image in.
Item {
    id: root
    property string source
    property string referer
    property string title
    property int radius: Theme.radiusMd
    property real zoom: 1
    property color tint: Theme.surface2
    readonly property bool ready: image.status === Image.Ready

    clip: false

    Rectangle {
        id: placeholder
        anchors.fill: parent
        radius: root.radius
        color: root.tint
        visible: !root.ready
        Text {
            anchors.fill: parent
            anchors.margins: 12
            visible: image.status === Image.Error || root.source.length === 0
            text: root.title
            color: Theme.textFaint
            font.family: Theme.fontDisplay
            font.pixelSize: 13
            wrapMode: Text.Wrap
            horizontalAlignment: Text.AlignHCenter
            verticalAlignment: Text.AlignVCenter
            elide: Text.ElideRight
        }
        Shimmer {
            anchors.fill: parent
            radius: root.radius
            visible: image.status === Image.Loading
        }
    }

    Item {
        id: content
        anchors.fill: parent
        visible: false
        layer.enabled: true
        Image {
            id: image
            anchors.centerIn: parent
            width: parent.width * root.zoom
            height: parent.height * root.zoom
            source: root.source ? App.image(root.source, root.referer) : ""
            sourceSize.width: Math.ceil(root.width * Screen.devicePixelRatio * 1.15)
            fillMode: Image.PreserveAspectCrop
            asynchronous: true
            cache: true
            smooth: true
            mipmap: false
        }
    }

    Rectangle {
        id: mask
        anchors.fill: parent
        radius: root.radius
        visible: false
        layer.enabled: true
    }

    MultiEffect {
        id: effect
        anchors.fill: parent
        source: content
        maskEnabled: true
        maskSource: mask
        maskThresholdMin: 0.5
        maskSpreadAtMin: 1.0
        opacity: root.ready ? 1 : 0
        scale: root.ready ? 1 : 1.03
        Behavior on opacity { NumberAnimation { duration: Motion.slow; easing.type: Easing.OutCubic } }
        Behavior on scale { NumberAnimation { duration: Motion.page; easing.type: Easing.OutCubic } }
    }
}
