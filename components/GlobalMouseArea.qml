import QtQuick
import Quickshell

LazyLoader {
    id: lazyLoader
    active: leftPanel.appfocused

    PanelWindow {
        id: globalScreen
        implicitWidth: Config.screenWidth - leftPanel.width
        implicitHeight: Config.screenHeight
        anchors {
            right: true
        }
        color: "transparent"
        exclusionMode: ExclusionMode.Ignore

        Item {
            id: exitScreen
            anchors.fill: parent

            MouseArea {
                id: globalMouseArea
                anchors.fill: parent
                propagateComposedEvents: true
                onClicked: {
                    leftPanel.appfocused = false;
                }
            }
        }
    }
}
