pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Services.Notifications
import Quickshell.Io
import "../js/ParseWindows.js" as ParseWindows
import "../js/UpdateFilter.js" as UpdateFilter
import "../js/UpdateRunningWindows.js" as UpdateRunningWindows

Singleton {
    id: config

    property color text: "#e6eaf0"//"#ffffff"
    property color textHover: "#65798b"
    property color progressColor: "#333b45"
    property color background: "#0f1115"//"#1e2127"
    property color foreground: "#181b21"//"#282b31"
    property color closeColor: "#e06c75"//"#ff5652"
    property color expandedColor: "#e5c07b"//"#ffbd2f"
    property color textselect: "#293038"//"#333B45"
    property color pinColor: "#98c379"//"#33C831"
    property int topbarwidth: 40
    property bool expandopen: false
    property int countWorkspace: 0
    property int currentworkspace: 0
    property int hoveredWorkspace: -1
    property int currentAppIndex: 0
    property int currentClipboardIndex: 0
    property string queryText: ""
    property bool notify: false
    property bool notifyVisible: false
    property bool calendarVisible: false
    property bool logoutVisible: false
    property bool clipboardVisible: false
    property bool toggleClipboard: false
    property bool toggleLeftPanel: false
    property bool toggleAppLauncher: false
    property bool toggleCollapseApp: false
    property bool killLoader: false
    property string fontFamily: "JetBrains Mono Nerd Font 10"
    property string userName: ""
    property string shellDir: ""
    property var filteredAppsModel: []

    onCurrentworkspaceChanged: hoveredWorkspace = -1

    property Timer windowsprocTimer: Timer {
        interval: 350
        running: config.toggleLeftPanel
        repeat: true
        onTriggered: windowsproc.running = true
    }

    property Timer workspaceTimer: Timer {
        interval: 350
        running: config.toggleLeftPanel
        repeat: true
        onTriggered: currentwsproc.running = true
    }

    property Timer countWorkspaceTimer: Timer {
        interval: 350
        running: config.toggleLeftPanel
        repeat: true
        onTriggered: countwsproc.running = true
    }

    property Timer appLauncherTimer: Timer {
        interval: 300
        running: false
        repeat: false
        onTriggered: {
            config.toggleAppLauncher = true
        }
    }

    property Timer delayLoader: Timer {
        interval: 300
        running: false
        repeat: false
        onTriggered: {
            Config.killLoader = false
        }
    }

    property alias runningWindowsModel: runningWindowsModelInternal
    ListModel {
        id: runningWindowsModelInternal
    }

    property alias notificationModel: notificationModelInternal
    ListModel {
        id: notificationModelInternal
    }

    property alias listPopupModel: listPopupModelInternal
    ListModel {
        id: listPopupModelInternal
        onCountChanged: {
            if (listPopupModel.count === 0) {
                config.notifyVisible = false;
            }
        }
    }

    NotificationServer {
        id: notifServer
        onNotification: function updateNotification(notification) {
            function pad(n) {
                return n < 10 ? "0" + n : n;
            }
            config.notifyVisible = true;
            let d = new Date();
            let now = pad(d.getHours()) + ":" + pad(d.getMinutes());
            let displayIcon = notification.appIcon || notification.image || "";

            notificationModel.insert(0, {
                icon: displayIcon,
                appName: notification.appName,
                summary: notification.summary,
                image: notification.image,
                body: notification.body,
                time: now
            });

            listPopupModel.insert(0, {
                icon: displayIcon,
                appName: notification.appName,
                summary: notification.summary,
                image: notification.image,
                body: notification.body,
                time: now
            });
        }
    }

    Component.onCompleted: {
        UpdateFilter.updateFilter("");
    }

    Process {
        id: windowsproc
        command: ["niri", "msg", "windows"]
        running: true
        stdout: StdioCollector {
            onStreamFinished: {
                ParseWindows.parseWindowsOutput(this.text, runningWindowsModel);
            }
        }
    }

    Process {
        id: currentwsproc
        command: ["bash", "-c", "niri msg workspaces | grep '*' | awk '{print $2}'"]
        running: true
        stdout: StdioCollector {
            onStreamFinished: {
                let text = this.text.trim();
                config.currentworkspace = text ? parseInt(text) : 1;
            }
        }
    }

    Process {
        id: countwsproc
        command: ["bash", "-c", "niri msg workspaces | tail -n 1 | awk '{print $NF}'"]
        running: true
        stdout: StdioCollector {
            onStreamFinished: {
                let text = this.text.trim();
                config.countWorkspace = text ? parseInt(text) : 1;
            }
        }
    }

    Process {
        id: homedirproc
        command: ["whoami"]
        running: true
        stdout: StdioCollector {
            onStreamFinished: {
                let text = this.text.trim();
                config.userName = text;
                config.shellDir = "/home/" + text + "/.config/quickshell/shell";
            }
        }
    }
}
