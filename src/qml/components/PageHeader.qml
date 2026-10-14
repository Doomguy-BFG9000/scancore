import QtQuick
import ScanCore

// Large page title with an optional subtitle and trailing controls.
Item {
    id: header
    property string title
    property string subtitle
    property bool showBack: false
    default property alias trailing: trailingRow.data

    width: parent ? parent.width : 800
    implicitHeight: column.implicitHeight + 28

    IconButton {
        id: back
        visible: header.showBack
        x: Theme.gutter - 8
        y: 26
        iconName: "arrow-left"
        tip: "Back"
        onClicked: Router.back()
    }

    Column {
        id: column
        x: header.showBack ? Theme.gutter + 34 : Theme.gutter
        y: 24
        width: parent.width - x - trailingRow.width - Theme.gutter - 12
        spacing: 4
        Text {
            width: parent.width
            text: header.title
            color: Theme.text
            font.family: Theme.fontDisplay
            font.pixelSize: Theme.text3xl
            font.weight: Font.Bold
            font.letterSpacing: -0.6
            elide: Text.ElideRight
        }
        Text {
            visible: text.length > 0
            width: parent.width
            text: header.subtitle
            color: Theme.textMuted
            font.family: Theme.fontSans
            font.pixelSize: Theme.textMd
            elide: Text.ElideRight
        }
    }

    Row {
        id: trailingRow
        anchors.right: parent.right
        anchors.rightMargin: Theme.gutter
        y: 30
        spacing: 8
    }
}
