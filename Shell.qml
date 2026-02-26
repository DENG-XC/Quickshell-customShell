//@ pragma UseQApplication

import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Io
import Quickshell.Wayland
import "components"

ShellRoot {
    id: root

    IpcHandler {
        target: "Config"

        function setAppLauncher(): void {
            if (Config.toggleCollapseApp) {
                Config.toggleCollapseApp = false;
                Config.killLoader = true;
                Config.appLauncherTimer.running = true;
            } else if (leftPanel.ispin && leftPanel.collapsed) {
                Config.appLauncherTimer.running = true;
                Config.killLoader = true;
                leftPanel.collapsed = false;
                Config.toggleLeftPanel = true;
                Config.toggleCollapseApp = true;
            } else if (leftPanel.ispin && Config.toggleLeftPanel) {
                Config.appLauncherTimer.running = true;
                Config.killLoader = true;
            } else if (leftPanel.collapsed) {
                Config.appLauncherTimer.running = true;
                Config.killLoader = true;
                leftPanel.collapsed = false;
                Config.toggleLeftPanel = true;
                Config.toggleCollapseApp = true;
            } else {
                Config.appLauncherTimer.running = true;
                Config.toggleLeftPanel = true;
                Config.killLoader = true;
            }
        }
    }

    PanelWindow {
        id: panelwindow
        implicitHeight: Screen.height
        implicitWidth: Screen.width
        color: "transparent"
        exclusionMode: ExclusionMode.Ignore

        mask: Region {
            item: maskrect
            intersection: Intersection.Xor
        }

        Rectangle {
            id: maskrect
            anchors.fill: rpcontainer
            visible: false
            anchors.bottomMargin: 0
            anchors.leftMargin: 0
            anchors.rightMargin: 0
            anchors.topMargin: Config.topbarwidth
            radius: 25
        }

        Item {
            id: rpcontainer
            anchors.right: parent.right
            anchors.top: parent.top
            height: parent.height
            width: parent.width - leftPanel.width

            Topbarbutton {
                id: topbarbutton
            }
            Shapepath {
                id: shapepath
            }
        }

        LazyLoader {
            id: logoutMenu
            active: Config.logoutVisible

            Logout {
                id: logoutMenu
            }
        }

        LazyLoader {
            id: popupMiniCalendar
            active: Config.calendarVisible || killLoader

            property bool killLoader: false

            PopupWindow {
                id: calendarPopup
                anchor.window: panelwindow
                anchor.rect.x: Config.toggleLeftPanel ? (rpcontainer.width / 2 + leftPanel.width) - width / 2 : rpcontainer.width / 2 - width / 2
                anchor.rect.y: 60
                implicitWidth: 390
                implicitHeight: 360
                color: "transparent"
                visible: true

                Component.onCompleted: {
                    popupMiniCalendar.killLoader = true;
                    if (Config.calendarVisible === true) {
                        enterAnim.start();
                    }
                }

                Connections {
                    target: Config
                    function onCalendarVisibleChanged() {
                        if (Config.calendarVisible === true) {
                            popupMiniCalendar.killLoader = true;
                            enterAnim.start();
                            exitAnim.stop();
                        } else {
                            exitAnim.start();
                            enterAnim.stop();
                        }
                    }
                }

                ParallelAnimation {
                    id: enterAnim
                    running: false

                    onStarted: {
                        calendarPopup.visible = true;
                    }

                    PropertyAnimation {
                        target: calendar
                        property: "opacity"
                        from: 0
                        to: 1
                        duration: 200
                        easing.type: Easing.InOutQuad
                    }
                    PropertyAnimation {
                        target: calendar
                        property: "height"
                        from: 0
                        to: 360
                        duration: 200
                        easing.type: Easing.InOutQuad
                    }
                }

                ParallelAnimation {
                    id: exitAnim
                    running: false

                    PropertyAnimation {
                        target: calendar
                        property: "opacity"
                        from: 1
                        to: 0
                        duration: 200
                        easing.type: Easing.InOutQuad
                    }
                    PropertyAnimation {
                        target: calendar
                        property: "height"
                        from: 360
                        to: 0
                        duration: 200
                        easing.type: Easing.InOutQuad
                    }

                    onFinished: {
                        popupMiniCalendar.killLoader = false;
                    }
                }

                MiniCalendar {
                    id: calendar
                    opacity: 0
                    height: 0
                }
            }
        }

        LazyLoader {
            id: clipboardLoader
            active: Config.clipboardVisible

            Clipboard {
                id: clipboardManager
            }
        }

        LazyLoader {
            id: notifyPopupLoader
            active: Config.notifyVisible

            PopupWindow {
                anchor.window: panelwindow
                anchor.rect.x: Config.toggleLeftPanel ? (rpcontainer.width / 2 + leftPanel.width) - width / 2 : rpcontainer.width / 2 - width / 2
                anchor.rect.y: 60
                implicitWidth: Screen.width / 6
                implicitHeight: Math.max(1, notifyPopup.height)
                color: "transparent"
                visible: true

                NotifyPop {
                    id: notifyPopup
                    popupModel: Config.listPopupModel
                }
            }
        }

        Volumepop {
            id: volumeService
        }
    }

    PanelWindow {
        id: leftPanel
        implicitWidth: Config.toggleLeftPanel ? (leftPanel.collapsed ? 60 : leftPanel.panelwidth) : 0
        color: Config.background
        exclusionMode: ispin ? ExclusionMode.Auto : ExclusionMode.Ignore
        WlrLayershell.keyboardFocus: Config.toggleLeftPanel ? (Config.toggleAppLauncher ? WlrKeyboardFocus.Exclusive : WlrKeyboardFocus.None) : WlrKeyboardFocus.None

        anchors {
            left: true
            top: true
            bottom: true
        }

        property int panelwidth: Screen.width / 6
        property bool panelOpen: false
        property bool ispin: false
        property bool appfocused: false
        property bool collapsed: false

        Behavior on implicitWidth {
            NumberAnimation {
                duration: 200
                easing.type: Easing.InOutQuad
            }
        }

        MouseArea {
            id: leftPanelMouseArea
            anchors.fill: parent
            hoverEnabled: true

            onEntered: {
                Config.toggleLeftPanel = true;
                Config.killLoader = true;
            }
            onExited: {
                if (!leftPanel.ispin) {
                    Config.toggleLeftPanel = false;
                    Config.delayLoader.running = true;
                }
            }

            Loader {
                id: leftPanelLoader
                anchors.fill: parent
                active: Config.killLoader
                sourceComponent: leftPanelContent
            }

            Component {
                id: leftPanelContent

                Item {
                    id: leftPanelcontainer
                    anchors.fill: parent
                    anchors.topMargin: 40
                    anchors.leftMargin: leftPanel.collapsed ? 0 : 20
                    anchors.rightMargin: leftPanel.collapsed ? 0 : 20
                    anchors.bottomMargin: 20

                    ColumnLayout {
                        id: mainLayout
                        anchors.fill: parent
                        spacing: leftPanel.collapsed ? 0 : 20

                        Item {
                            id: workspacecontainer
                            Layout.preferredWidth: parent.width
                            Layout.preferredHeight: leftPanel.collapsed ? workspaces.width : Math.round(parent.height / 50)
                            Layout.fillHeight: false
                            UpWorkspaces {
                                id: upWorkspaces
                                visible: leftPanel.collapsed ? false : true
                            }
                            DownWorkspaces {
                                id: downWorkspaces
                                visible: leftPanel.collapsed ? false : true
                            }
                            Workspaces {
                                id: workspaces
                            }
                        }

                        Rectangle {
                            id: separator
                            color: Config.text
                            Layout.preferredHeight: 1
                            Layout.preferredWidth: 40
                            Layout.alignment: Qt.AlignHCenter
                            Layout.topMargin: 20
                            visible: leftPanel.collapsed ? true : false
                            opacity: leftPanel.collapsed ? 0.6 : 0

                            Behavior on opacity {
                                NumberAnimation {
                                    easing.type: Easing.InOutQuad
                                    duration: 200
                                }
                            }
                        }

                        Applauncher {
                            id: appLauncher
                        }

                        Menu {
                            id: menu
                        }

                        AppSwitch {
                            id: appSwitch
                        }

                        BottomContainer {
                            id: bottomContainer
                        }

                    }
                }
            }
        }
    }
}
