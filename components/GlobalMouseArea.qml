import QtQuick
import Quickshell

LazyLoader {
    id: lazyLoader
    active: leftPanel.appfocused

    PanelWindow {
        id: globalScreen
        screen: {
            for (let i = 0; i < Quickshell.screens.length; i++) {
                if (Quickshell.screens[i].name === Config.priScreen) {
                    return Quickshell.screens[i];
                }
            }
            return Quickshell.screens[0];
        }
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
