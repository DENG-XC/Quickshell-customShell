import QtQuick
import Quickshell

Text {
    id: downWorkspace
    text: ""
    anchors.right: parent.right
    anchors.verticalCenter: parent.verticalCenter
    color: Config.text
    font.pixelSize: 22
    font.bold: true
    font.family: "JetBrains Mono Nerd Font 10"

    MouseArea {
        id: downWorkspacetrigger
        anchors.fill: parent
        enabled: true
        hoverEnabled: true
        cursorShape: Qt.PointingHandCursor
        onClicked: {
            Buttoncommand.toggleDownWorkspace();
        }
    }
}
