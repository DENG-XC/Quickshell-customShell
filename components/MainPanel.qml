import QtQuick
import Quickshell

PanelWindow {
    id: mainPanel
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
            popupWindow: mainPanel
        }
        Shapepath {
            id: shapepath
        }
    }

    LazyLoader {
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
            anchor.window: mainPanel
            anchor.rect.x: leftPanel.panelOpen ? (rpcontainer.width / 2 + leftPanel.width) - width / 2 : rpcontainer.width / 2 - width / 2
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

        ClipboardTest {
            id: clipboardManager
        }
    }

    LazyLoader {
        id: notifyPopupLoader
        active: Config.notifyVisible

        PopupWindow {
            anchor.window: mainPanel
            anchor.rect.x: leftPanel.panelOpen ? (rpcontainer.width / 2 + leftPanel.width) - width / 2 : rpcontainer.width / 2 - width / 2
            anchor.rect.y: 60
            implicitWidth: Screen.width / 6
            implicitHeight: Math.max(1, notifyPopup.height)
            color: "transparent"
            visible: true

            NotifyPop {
                id: notifyPopup
                popupModel: listPopupModel
            }
        }
    }

    Volumepop {
        id: volumeService
    }
}
