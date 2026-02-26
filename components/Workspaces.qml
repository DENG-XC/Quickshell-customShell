import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Io

Item {
    id: workspaceindicator
    anchors.centerIn: parent
    implicitWidth: 12 * workspaceCount + ((workspaceCount - 1) * 20) + 40
    implicitHeight: parent.height
    rotation: leftPanel.collapsed ? 90 : 0

    property int workspaceCount: Config.countWorkspace

    RowLayout {
        spacing: 20
        anchors.centerIn: parent

        Repeater {
            model: workspaceindicator.workspaceCount
            delegate: Rectangle {
                id: workspaceRectangle

                property int workspaceId: index + 1
                property bool isCurrent: workspaceId === Config.currentworkspace
                property bool isHovered: workspaceId === Config.hoveredWorkspace
                property bool initialized: false

                color: Config.text
                implicitWidth: (!initialized && isCurrent) ? 12 : ((isCurrent || isHovered)) ? 40 : 12
                implicitHeight: 12
                radius: height / 2
                opacity: (isCurrent || isHovered) ? 1 : 0.5

                Component.onCompleted: {
                    initialized = true;
                }

                Behavior on implicitWidth {
                    NumberAnimation {
                        easing.type: Easing.InOutQuad
                        duration: 300
                    }
                }

                Behavior on opacity {
                    NumberAnimation {
                        easing.type: Easing.InOutQuad
                        duration: 300
                    }
                }

                MouseArea {
                    anchors.fill: workspaceRectangle
                    hoverEnabled: true
                    cursorShape: Qt.PointingHandCursor

                    onEntered: {
                        Config.hoveredWorkspace = workspaceId;
                    }
                    onExited: {
                        if (Config.hoveredWorkspace === workspaceId) {
                            Config.hoveredWorkspace = -1;
                        }
                    }
                    onClicked: {
                        Buttoncommand.focusWorkspace(workspaceId);
                    }
                }
            }
        }
    }
}
