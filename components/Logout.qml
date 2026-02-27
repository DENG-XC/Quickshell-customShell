import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Io
import Quickshell.Wayland

Scope {
    id: logoutRoot

    property string uptime
    property list<LogoutButton> buttons: [
        LogoutButton {
            command: "qs -p " + Config.shellDir + "/LockScreen.qml"
            keybind: Qt.Key_K
            text: ""
        },
        LogoutButton {
            command: "loginctl terminate-user $USER"
            keybind: Qt.Key_E
            text: ""
        },
        LogoutButton {
            command: "reboot"
            keybind: Qt.Key_U
            text: ""
        },
        LogoutButton {
            command: "poweroff"
            keybind: Qt.Key_H
            text: ""
        }
    ]

    Process {
        id: uptimeProcess
        command: ["uptime", "-p"]
        running: true

        stdout: StdioCollector {
            onStreamFinished: logoutRoot.uptime = this.text
        }
    }

    Variants {
        id: logoutScreen
        model: Quickshell.screens

        PanelWindow {
            id: logoutwindow
            implicitWidth: Screen.width
            implicitHeight: Screen.height
            color: "transparent"

            required property var modelData
            screen: modelData

            exclusionMode: ExclusionMode.Ignore
            WlrLayershell.layer: WlrLayer.Overlay
            WlrLayershell.keyboardFocus: WlrKeyboardFocus.Exclusive

            contentItem {
                focus: true
                Keys.onPressed: event => {
                    if (event.key === Qt.Key_Escape)
                        Config.logoutVisible = false;
                    else {
                        for (let i = 0; i < buttons.length; i++) {
                            let button = buttons[i];
                            if (event.key === button.keybind)
                                button.exec(button.text);
                        }
                    }
                }
            }

            Rectangle {
                id: mousearea
                anchors.fill: parent
                color: "transparent"

                MouseArea {
                    anchors.fill: parent
                    onClicked: {
                        Config.logoutVisible = false;
                    }
                }

                Rectangle {
                    id: container
                    anchors.centerIn: parent
                    color: Config.background
                    implicitWidth: Screen.width / 2.5
                    implicitHeight: Screen.height / 3.5
                    radius: 60

                    Rectangle {
                        id: textcontainer
                        color: "transparent"
                        anchors.top: parent.top
                        anchors.horizontalCenter: parent.horizontalCenter
                        implicitWidth: parent.width - 100
                        implicitHeight: parent.height - buttonbackground.height - 50

                        Rectangle {
                            id: usercontainer
                            color: Config.foreground
                            anchors.verticalCenter: parent.verticalCenter
                            anchors.left: parent.left
                            radius: 60
                            implicitWidth: parent.width * 0.1
                            implicitHeight: parent.height * 0.3

                            Text {
                                id: user
                                text: Config.userName
                                color: Config.textHover
                                font.family: "JetBrains Mono Nerd Font 10"
                                font.pointSize: 14
                                font.bold: true
                                anchors.centerIn: parent
                            }
                        }

                        Rectangle {
                            id: uptimecontainer
                            color: Config.foreground
                            anchors.verticalCenter: parent.verticalCenter
                            anchors.right: parent.right
                            radius: 60
                            implicitWidth: parent.width * 0.3
                            implicitHeight: parent.height * 0.3

                            Text {
                                id: uptime
                                text: logoutRoot.uptime
                                color: Config.textHover
                                font.family: "JetBrains Mono Nerd Font 10"
                                font.pointSize: 14
                                font.bold: true
                                anchors.centerIn: parent
                            }
                        }
                    }

                    Rectangle {
                        id: buttonbackground
                        color: Config.foreground
                        radius: 60
                        implicitHeight: parent.height / 2
                        implicitWidth: parent.width - 100
                        y: parent.height * 0.5 - 50
                        anchors.horizontalCenter: parent.horizontalCenter
                    }

                    GridLayout {
                        y: parent.height * 0.5 - 50
                        anchors.horizontalCenter: parent.horizontalCenter
                        height: parent.height / 2
                        width: parent.width - 100

                        columns: 4
                        columnSpacing: 0
                        rowSpacing: 0

                        Repeater {
                            model: logoutRoot.buttons
                            delegate: Rectangle {
                                id: logoutButtonDelegate
                                required property LogoutButton modelData
                                Layout.fillWidth: true
                                Layout.fillHeight: true
                                color: "transparent"

                                MouseArea {
                                    id: exec
                                    anchors.fill: parent
                                    cursorShape: Qt.PointingHandCursor
                                    hoverEnabled: true
                                    onEntered: {
                                        buttonhover.color = Config.textHover;
                                    }
                                    onExited: {
                                        buttonhover.color = "transparent";
                                    }
                                    onClicked: {
                                        modelData.exec(modelData.text);
                                    }
                                }

                                Text {
                                    anchors.centerIn: parent
                                    text: modelData.text
                                    color: Config.text
                                    font.pointSize: 60
                                    font.bold: true
                                    font.family: "JetBrains Mono Nerd Font 10"
                                    z: 2
                                }

                                Rectangle {
                                    id: buttonhover
                                    color: "transparent"
                                    anchors.fill: parent
                                    z: 1
                                    radius: 60

                                    Behavior on color {
                                        PropertyAnimation {
                                            duration: 200
                                            easing.type: Easing.InOutQuad
                                        }
                                    }
                                }
                            }
                        }
                    }
                }
            }
        }
    }
}
