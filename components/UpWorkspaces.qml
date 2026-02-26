import Quickshell
import QtQuick

Text {
    id: upWorkspace
    text: ""
    anchors.left: parent.left
    anchors.verticalCenter: parent.verticalCenter
    color: Config.text
    font.pixelSize: 22
    font.bold: true
    font.family: "JetBrains Mono Nerd Font 10"
    opacity: 1

    MouseArea {
        id: upWorkspacetrigger
        anchors.fill: parent
        enabled: true
        hoverEnabled: true
        cursorShape: Qt.PointingHandCursor
        onClicked: {
            Buttoncommand.toggleUpWorkspace();
        }
    }
}
