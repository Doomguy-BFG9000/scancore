import QtQuick
import ScanCore

// One labelled setting with its control on the right.
Item {
    id: row
    property string title
    property string description
    default property alias control: holder.data

    width: parent ? parent.width : 600
    implicitHeight: (Theme.compact ? texts.implicitHeight + holder.height + 12 : Math.max(texts.implicitHeight, holder.childrenRect.height)) + 26

    Rectangle {
        anchors.bottom: parent.bottom
        width: parent.width
        height: 1
        color: Theme.border
    }
    Column {
        id: texts
        y: Theme.compact ? 13 : (parent.height - height) / 2
        width: Theme.compact ? parent.width : parent.width - holder.width - 24
        spacing: 3
        Text {
            width: parent.width
            text: row.title
            color: Theme.text
            font.family: Theme.fontSans
            font.pixelSize: Theme.textMd
            font.weight: Font.Medium
            wrapMode: Text.Wrap
        }
        Text {
            width: parent.width
            visible: text.length > 0
            text: row.description
            color: Theme.textMuted
            font.family: Theme.fontSans
            font.pixelSize: Theme.textSm
            wrapMode: Text.Wrap
        }
    }
    Item {
        id: holder
        x: Theme.compact ? 0 : parent.width - width
        y: Theme.compact ? texts.y + texts.implicitHeight + 12 : (parent.height - height) / 2
        width: childrenRect.width
        height: childrenRect.height
    }
}
