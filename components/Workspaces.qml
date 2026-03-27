import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Io

Item {
    id: workspaceindicator
    anchors.centerIn: parent
    implicitWidth: Config.sc(12) * workspaceCount + ((workspaceCount - 1) * Config.sc(20)) + Config.sc(40)
    implicitHeight: parent.height
    rotation: leftPanel.collapsed ? 90 : 0

    property int workspaceCount: Config.countWorkspace

    RowLayout {
        spacing: Config.sc(20)
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
                implicitWidth: (!initialized && isCurrent) ? Config.sc(12) : ((isCurrent || isHovered)) ? Config.sc(40) : Config.sc(12)
                implicitHeight: Config.sc(12)
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
