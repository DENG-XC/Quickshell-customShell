//@ pragma UseQApplication

import QtQuick
import QtQuick.Layouts
import QtQuick.Controls
import Quickshell
import Quickshell.Io
import Quickshell.Wayland
import "components"

ShellRoot {
    id: root

    IpcHandler {
        target: "Config"

        function setAppLauncher(a: string, d: string): void {
            if (a === "n" && d === "n") {
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
            if (a === "t" && d === "f") {
                if (leftPanel.ispin) {
                    return;
                } else if (Config.toggleLeftPanel) {
                    Config.toggleLeftPanel = false;
                    Config.delayLoader.running = true;
                } else {
                    Config.toggleLeftPanel = true;
                    Config.killLoader = true;
                }
            }
            if (a === "f" && d === "t") {
                if (!Config.toggleLeftPanel) {
                    return;
                } else if (!leftPanel.ispin) {
                    leftPanel.ispin = true;
                } else {
                    leftPanel.ispin = false;
                }
            }
            if (a === "t" && d === "t") {
                if (!Config.toggleLeftPanel) {
                    return;
                } else if (leftPanel.collapsed) {
                    leftPanel.collapsed = false;
                } else {
                    leftPanel.collapsed = true;
                }
            }
        }
    }

    PanelWindow {
        id: panelwindow
        implicitHeight: Config.screenHeight
        implicitWidth: Config.screenWidth
        color: "transparent"
        exclusionMode: ExclusionMode.Ignore
        WlrLayershell.keyboardFocus: Config.toggleLeftPanel ? (Config.toggleAppLauncher ? WlrKeyboardFocus.Exclusive : WlrKeyboardFocus.None) : WlrKeyboardFocus.None

        screen: {
            for (let i = 0; i < Quickshell.screens.length; i++) {
                if (Quickshell.screens[i].name === Config.priScreen) {
                    return Quickshell.screens[i];
                }
            }
            return Quickshell.screens[0];
        }

        mask: Region {
            item: maskrect
            intersection: Intersection.Xor
        }

        Rectangle {
            id: maskrect
            // anchors.top: parent.top
            // anchors.bottom: parent.bottom
            // anchors.right: parent.right
            anchors.fill: rpcontainer
            visible: false
            anchors.bottomMargin: 0
            anchors.leftMargin: Config.sc(30)
            anchors.rightMargin: 0
            anchors.topMargin: Config.sc(Config.topbarwidth)
        }

        Rectangle {
            id: leftPanel
            width: Config.toggleLeftPanel ? (leftPanel.collapsed ? Config.sc(60) : leftPanel.panelwidth) : 0
            color: Config.background
            anchors.left: parent.left
            anchors.top: parent.top
            anchors.bottom: parent.bottom

            // exclusionMode: ispin ? ExclusionMode.Auto : ExclusionMode.Ignore
            // WlrLayershell.keyboardFocus: Config.toggleLeftPanel ? (Config.toggleAppLauncher ? WlrKeyboardFocus.Exclusive : WlrKeyboardFocus.None) : WlrKeyboardFocus.None

            property int panelwidth: Math.round(Config.screenWidth / 6)
            property bool panelOpen: false
            property bool ispin: false
            property bool appfocused: false
            property bool collapsed: false

            Behavior on width {
                NumberAnimation {
                    duration: 200
                    easing.type: Easing.InOutQuad
                }
            }

            MouseArea {
                id: leftPanelTrigger
                anchors.left: parent.left
                width: parent.width + Config.sc(30)
                height: parent.height
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
                        anchors.topMargin: Config.sc(40)
                        anchors.leftMargin: leftPanel.collapsed ? 0 : Config.sc(Config.gaps)
                        anchors.rightMargin: leftPanel.collapsed ? Config.sc(30) : Config.sc(50)
                        anchors.bottomMargin: Config.sc(Config.gaps)

                        ColumnLayout {
                            id: mainLayout
                            anchors.fill: parent
                            spacing: leftPanel.collapsed ? 0 : Config.sc(20)

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
                                Layout.preferredWidth: Config.sc(40)
                                Layout.alignment: Qt.AlignHCenter
                                Layout.topMargin: Config.sc(Config.gaps)
                                visible: leftPanel.collapsed
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

        Item {
            id: rpcontainer
            anchors.right: parent.right
            anchors.top: parent.top
            anchors.bottom: parent.bottom
            anchors.left: leftPanel.right
            // height: parent.height
            // width: parent.width - leftPanel.width

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
                id: logoutMenus
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
                anchor.rect.y: Config.sc(Config.topbarwidth) + Config.sc(Config.gaps)
                implicitWidth: Config.sc(390)
                implicitHeight: Config.sc(360)
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
                        to: Config.sc(360)
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
                        from: Config.sc(360)
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
            id: configLoader
            active: Config.configPanelVisible

            ConfigPanel {
                id: configPanelManager
            }
        }

        // WiFi Password Popup
        LazyLoader {
            id: wifiPasswordPopupLoader
            active: Config.wifiPasswordPopupVisible

            FloatingWindow {
                id: wifiPasswordPopup
                color: "transparent"
                title: "wifiPopup"
                visible: true
                maximumSize: Qt.size(Config.sc(360), Config.sc(220))

                onVisibleChanged: {
                    if (visible) {
                        wifiPasswordField.forceActiveFocus();
                    } else {
                        // 窗口被关闭时，同步状态
                        Config.wifiPasswordPopupVisible = false;
                        wifiPasswordField.text = "";
                    }
                }

                Rectangle {
                    id: wifiPasswordPopupContent
                    width: Config.sc(360)
                    height: Config.sc(220)
                    anchors.centerIn: parent
                    color: Config.foreground
                    radius: Config.sc(25)

                    ColumnLayout {
                        anchors.fill: parent
                        anchors.margins: Config.sc(24)
                        spacing: Config.sc(24)

                        // WiFi Name
                        Text {
                            text: Config.selectedWifi ? Config.selectedWifi.name : "WiFi"
                            color: Config.text
                            font.pixelSize: Config.scFont(18)
                            font.bold: true
                            font.family: Config.fontFamily
                            Layout.alignment: Qt.AlignHCenter
                        }

                        // Password Field
                        Rectangle {
                            Layout.fillWidth: true
                            Layout.preferredHeight: Config.sc(44)
                            color: Config.background
                            radius: Config.sc(15)
                            border.color: wifiPasswordField.activeFocus ? Config.textHover : Config.progressColor
                            border.width: 1

                            RowLayout {
                                anchors.fill: parent
                                anchors.leftMargin: Config.sc(12)
                                anchors.rightMargin: Config.sc(12)

                                TextField {
                                    id: wifiPasswordField
                                    Layout.fillWidth: true
                                    color: Config.text
                                    font.pixelSize: Config.scFont(15)
                                    font.family: Config.fontFamily
                                    echoMode: TextInput.Password
                                    background: Rectangle {
                                        color: "transparent"
                                    }
                                    selectByMouse: true
                                    placeholderText: "Password"
                                    placeholderTextColor: Qt.rgba(1, 1, 1, 0.4)
                                    focus: true
                                }

                                Text {
                                    text: wifiPasswordField.echoMode === TextInput.Password ? "\uf06e" : "\uf070"
                                    font.pixelSize: Config.scFont(14)
                                    font.family: Config.fontFamily
                                    color: Config.text
                                    opacity: 0.6

                                    MouseArea {
                                        anchors.fill: parent
                                        cursorShape: Qt.PointingHandCursor
                                        onClicked: {
                                            wifiPasswordField.echoMode = wifiPasswordField.echoMode === TextInput.Password ? TextInput.Normal : TextInput.Password;
                                        }
                                    }
                                }
                            }
                        }

                        // Buttons
                        RowLayout {
                            Layout.fillWidth: true
                            spacing: Config.sc(12)

                            // Cancel Button
                            Item {
                                Layout.fillWidth: true
                                Layout.preferredHeight: Config.sc(40)

                                property bool pressed: false

                                Rectangle {
                                    anchors.fill: parent
                                    color: Config.progressColor
                                    radius: Config.sc(15)
                                    scale: parent.pressed ? 0.95 : 1

                                    Behavior on scale {
                                        NumberAnimation {
                                            duration: 100
                                            easing.type: Easing.InOutQuad
                                        }
                                    }

                                    Text {
                                        anchors.centerIn: parent
                                        text: "Cancel"
                                        color: Config.text
                                        font.pixelSize: Config.scFont(14)
                                        font.family: Config.fontFamily
                                    }
                                }

                                MouseArea {
                                    anchors.fill: parent
                                    cursorShape: Qt.PointingHandCursor
                                    onPressed: parent.pressed = true
                                    onReleased: parent.pressed = false
                                    onClicked: {
                                        Config.wifiPasswordPopupVisible = false;
                                        wifiPasswordField.text = "";
                                    }
                                }
                            }

                            // Connect Button
                            Item {
                                Layout.fillWidth: true
                                Layout.preferredHeight: Config.sc(40)

                                property bool pressed: false

                                Rectangle {
                                    anchors.fill: parent
                                    color: Config.textHover
                                    radius: Config.sc(15)
                                    scale: parent.pressed ? 0.95 : 1

                                    Behavior on scale {
                                        NumberAnimation {
                                            duration: 100
                                            easing.type: Easing.InOutQuad
                                        }
                                    }

                                    Text {
                                        anchors.centerIn: parent
                                        text: "Connect"
                                        color: Config.text
                                        font.pixelSize: Config.scFont(14)
                                        font.family: Config.fontFamily
                                    }
                                }

                                MouseArea {
                                    anchors.fill: parent
                                    cursorShape: Qt.PointingHandCursor
                                    onPressed: parent.pressed = true
                                    onReleased: parent.pressed = false
                                    onClicked: {
                                        if (Config.selectedWifi) {
                                            Buttoncommand.wifiConnect(Config.selectedWifi.name, wifiPasswordField.text);
                                        }
                                        Config.wifiPasswordPopupVisible = false;
                                        wifiPasswordField.text = "";
                                    }
                                }
                            }
                        }
                    }
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
                anchor.rect.y: Config.sc(Config.topbarwidth) + Config.sc(Config.gaps)
                implicitWidth: Math.round(Config.screenWidth / 6)
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

        LazyLoader {
            id: screenLock
            active: Config.lockVisible

            ScreenLock {
                id: screenLockManager
            }
        }
    }
}
