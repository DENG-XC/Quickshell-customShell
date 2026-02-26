import QtQuick
import Quickshell

LazyLoader {
    id: lazyLoader
    active: leftPanel.appfocused

    PanelWindow {
        id: globalScreen
        implicitWidth: Screen.width - leftPanel.width
        implicitHeight: Screen.height
        anchors {
            right: true
        }
        color: "transparent"
        exclusionMode: ExclusionMode.Ignore

        Item {
            id: exitScreen
            anchors.fill: parent
            //z: 1000

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
