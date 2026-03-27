import Quickshell
import QtQuick

Text {
    id: upWorkspace
    text: ""
    anchors.left: parent.left
    anchors.verticalCenter: parent.verticalCenter
    color: Config.text
    font.pixelSize: Config.scFont(22)
    font.bold: true
    font.family: Config.fontFamily
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
