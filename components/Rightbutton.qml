import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Io

RowLayout {
    id: rightButtonLayout
    spacing: 20
    anchors.right: parent.right
    implicitWidth: parent.width
    implicitHeight: parent.height
    anchors.verticalCenter: parent.verticalCenter

    Text {
        id: screenshot
        Layout.alignment: Qt.AlignCenter
        text: ""
        color: Config.text
        font.pixelSize: 22
        font.bold: true
        font.family: "JetBrains Mono Nerd Font 10"

        MouseArea {
            id: screenshottrigger
            anchors.fill: parent
            enabled: true
            cursorShape: Qt.PointingHandCursor
            onClicked: {
                Buttoncommand.toggleScreenshot();
            }
        }
    }

    Text {
        id: colorpicker
        Layout.alignment: Qt.AlignCenter
        text: ""
        color: Config.text
        font.pixelSize: 22
        font.bold: true
        font.family: "JetBrains Mono Nerd Font 10"

        MouseArea {
            id: colorpickertrigger
            anchors.fill: parent
            enabled: true
            cursorShape: Qt.PointingHandCursor
            onClicked: {
                Buttoncommand.toggleColorPicker();
            }
        }
    }
}
