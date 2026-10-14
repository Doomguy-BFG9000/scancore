import QtQuick
import QtQuick.Controls.Basic
import ScanCore

// Dropdown. model: [{value, label}] ; bind `value`, handle `picked`.
ComboBox {
    id: control
    property var value
    signal picked(var value)

    textRole: "label"
    valueRole: "value"
    implicitHeight: 36
    implicitWidth: Math.max(140, contentItem.implicitWidth + 48)
    font.family: Theme.fontSans
    font.pixelSize: Theme.textSm
    hoverEnabled: true

    Component.onCompleted: currentIndex = Math.max(0, indexOfValue(value))
    onValueChanged: currentIndex = Math.max(0, indexOfValue(value))
    onModelChanged: currentIndex = Math.max(0, indexOfValue(value))
    onActivated: (index) => picked(valueAt(index))

    background: Rectangle {
        radius: Theme.radiusMd
        color: control.hovered || control.popup.visible ? Theme.surface3 : Theme.surface2
        border.width: 1
        border.color: control.visualFocus ? Theme.accent : Theme.border
        Behavior on color { ColorAnimation { duration: Motion.fast } }
    }
    contentItem: Text {
        leftPadding: 14
        rightPadding: 30
        text: control.displayText
        font: control.font
        color: Theme.text
        verticalAlignment: Text.AlignVCenter
        elide: Text.ElideRight
    }
    indicator: Icon {
        x: control.width - width - 12
        anchors.verticalCenter: parent.verticalCenter
        name: "chevron-down"
        size: 14
        color: Theme.textMuted
        rotation: control.popup.visible ? 180 : 0
        Behavior on rotation { NumberAnimation { duration: Motion.normal; easing.type: Easing.OutCubic } }
    }
    delegate: ItemDelegate {
        id: option
        required property var modelData
        required property int index
        width: ListView.view ? ListView.view.width : 200
        height: 34
        hoverEnabled: true
        contentItem: Text {
            text: option.modelData.label
            color: Theme.text
            font.family: Theme.fontSans
            font.pixelSize: Theme.textSm
            font.weight: control.currentIndex === option.index ? Font.DemiBold : Font.Normal
            verticalAlignment: Text.AlignVCenter
            elide: Text.ElideRight
        }
        background: Rectangle {
            radius: Theme.radiusSm
            color: option.hovered ? Theme.surface3 : "transparent"
        }
    }
    popup: Popup {
        y: control.height + 6
        width: Math.max(control.width, 180)
        implicitHeight: Math.min(contentItem.implicitHeight + 12, 360)
        padding: 6
        transformOrigin: Item.Top
        enter: Transition {
            ParallelAnimation {
                NumberAnimation { property: "opacity"; from: 0; to: 1; duration: Motion.fast }
                NumberAnimation { property: "scale"; from: 0.96; to: 1; duration: Motion.normal; easing.type: Easing.OutCubic }
            }
        }
        exit: Transition { NumberAnimation { property: "opacity"; to: 0; duration: Motion.instant } }
        contentItem: ListView {
            clip: true
            implicitHeight: contentHeight
            model: control.popup.visible ? control.delegateModel : null
            currentIndex: control.highlightedIndex
            ScrollIndicator.vertical: ScrollIndicator {}
        }
        background: Rectangle {
            radius: Theme.radiusMd
            color: Theme.surface
            border.width: 1
            border.color: Theme.borderStrong
        }
    }
}
