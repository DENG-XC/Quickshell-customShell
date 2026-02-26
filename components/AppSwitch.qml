import QtQuick
import QtQuick.Layouts
import Quickshell
import "../js/SearchAppIcon.js" as SearchAppIcon

Item {
                            id: appSwitch
                            Layout.preferredWidth: parent.width
                            Layout.alignment: Qt.AlignHCenter
                            Layout.fillHeight: true
                            clip: true

                            ListView {
                                id: appListView
                                width: leftPanel.collapsed ? parent.width - 20 : parent.width
                                height: parent.height
                                anchors.horizontalCenter: parent.horizontalCenter
                                anchors.top: parent.top
                                anchors.topMargin: leftPanel.collapsed ? 20 : 0
                                model: Config.runningWindowsModel
                                spacing: 20

                                add: Transition {
                                    ParallelAnimation {
                                        NumberAnimation {
                                            property: "x"
                                            from: -appSwitch.width
                                            to: 0
                                            duration: 300
                                            easing.type: Easing.InOutQuad
                                        }
                                        NumberAnimation {
                                            property: "opacity"
                                            from: 0
                                            to: 1
                                            duration: 300
                                            easing.type: Easing.InOutQuad
                                        }
                                    }
                                }

                                remove: Transition {
                                    ParallelAnimation {
                                        NumberAnimation {
                                            property: "opacity"
                                            from: 1
                                            to: 0
                                            duration: 300
                                            easing.type: Easing.InOutQuad
                                        }
                                        NumberAnimation {
                                            property: "x"
                                            from: 0
                                            to: -appSwitch.width
                                            duration: 300
                                            easing.type: Easing.InOutQuad
                                        }
                                    }
                                }

                                delegate: Item {
                                    id: listViewItem
                                    width: appListView.width
                                    height: leftPanel.collapsed ? appListView.width : 70

                                    property bool hovered: false
                                    property bool closeHovered: false
                                    property bool collapsedFinished: true

                                    Connections {
                                        target: leftPanel
                                        function onCollapsedChanged() {
                                            if (leftPanel.collapsed) {
                                                listViewItem.collapsedFinished = false;
                                                finishTimer.start();
                                            } else {
                                                listViewItem.collapsedFinished = true;
                                            }
                                        }
                                    }

                                    Timer {
                                        id: finishTimer
                                        interval: 250
                                        running: leftPanel.collapsed
                                        repeat: false
                                        onTriggered: {
                                            listViewItem.collapsedFinished = true;
                                        }
                                    }
                                    SequentialAnimation {
                                        id: pressAnimation
                                        running: false

                                        ParallelAnimation {
                                            NumberAnimation {
                                                target: appSwitchItem
                                                property: "scale"
                                                from: 1
                                                to: 0.9
                                                duration: 50
                                                easing.type: Easing.OutQuad
                                            }

                                            NumberAnimation {
                                                target: appSwitchBackground
                                                property: "scale"
                                                from: 1
                                                to: 0.9
                                                duration: 50
                                                easing.type: Easing.OutQuad
                                            }
                                        }
                                    }

                                    SequentialAnimation {
                                        id: releaseAnimation
                                        running: false

                                        ParallelAnimation {
                                            NumberAnimation {
                                                target: appSwitchItem
                                                property: "scale"
                                                from: 0.9
                                                to: 1
                                                duration: 50
                                                easing.type: Easing.OutQuad
                                            }

                                            NumberAnimation {
                                                target: appSwitchBackground
                                                property: "scale"
                                                from: 0.9
                                                to: 1
                                                duration: 50
                                                easing.type: Easing.OutQuad
                                            }
                                        }

                                        onStarted: {
                                            Buttoncommand.toggleWindowSwitch(windowId);
                                        }
                                    }

                                    Rectangle {
                                        id: appSwitchBackground
                                        anchors.fill: parent
                                        color: Config.textHover
                                        radius: leftPanel.collapsed ? 10 : 25
                                        scale: 1
                                        opacity: focused ? 1 : (hovered ? 0.3 : 0)
                                        visible: listViewItem.collapsedFinished

                                        Behavior on opacity {
                                            NumberAnimation {
                                                duration: 200
                                            }
                                        }
                                    }

                                    Item {
                                        id: appSwitchItem
                                        anchors.fill: parent
                                        scale: 1

                                        Image {
                                            id: appIcon
                                            source: SearchAppIcon.searchAppIcon(icon)
                                            anchors.verticalCenter: parent.verticalCenter
                                            x: leftPanel.collapsed ? parent.width / 2 - width / 2 : 20
                                            width: leftPanel.collapsed ? 28 : 52
                                            height: leftPanel.collapsed ? 28 : 52
                                            sourceSize.width: leftPanel.collapsed ? 28 : 52
                                            sourceSize.height: leftPanel.collapsed ? 28 : 52
                                            asynchronous: true
                                            fillMode: Image.PreserveAspectFit
                                        }

                                        Text {
                                            id: appText
                                            text: appId
                                            color: Config.text
                                            font.pixelSize: 16
                                            font.bold: true
                                            font.family: Config.fontFamily
                                            anchors.verticalCenter: parent.verticalCenter
                                            anchors.left: appIcon.right
                                            anchors.leftMargin: 20
                                            z: 1
                                            visible: leftPanel.collapsed ? false : true
                                        }

                                        MouseArea {
                                            anchors.fill: parent
                                            hoverEnabled: true
                                            cursorShape: Qt.PointingHandCursor
                                            onPressed: {
                                                pressAnimation.start();
                                            }
                                            onReleased: {
                                                releaseAnimation.start();
                                            }
                                            onEntered: listViewItem.hovered = true
                                            onExited: listViewItem.hovered = false

                                            Rectangle {
                                                id: closebutton
                                                height: leftPanel.collapsed ? 14 : 26
                                                width: leftPanel.collapsed ? 14 : 26
                                                radius: height / 2
                                                color: Config.closeColor
                                                x: leftPanel.collapsed ? parent.width - width / 2 : parent.width - width - 20
                                                y: leftPanel.collapsed ? -height / 2 : parent.height - parent.height / 2 - height / 2
                                                opacity: leftPanel.collapsed ? (listViewItem.hovered ? (listViewItem.closeHovered ? 1 : 0.6) : 0) : (listViewItem.closeHovered ? 1 : 0.6)
                                                visible: listViewItem.collapsedFinished

                                                Behavior on opacity {
                                                    NumberAnimation {
                                                        duration: 200
                                                        easing.type: Easing.InOutQuad
                                                    }
                                                }

                                                MouseArea {
                                                    anchors.fill: parent
                                                    hoverEnabled: true
                                                    cursorShape: Qt.PointingHandCursor
                                                    onEntered: {
                                                        listViewItem.closeHovered = true;
                                                    }
                                                    onExited: {
                                                        listViewItem.closeHovered = false;
                                                    }
                                                    onClicked: {
                                                        Buttoncommand.killWindow(windowId);
                                                    }
                                                }

                                                Text {
                                                    id: closeMark
                                                    text: ""
                                                    color: Config.background
                                                    font.pointSize: leftPanel.collapsed ? 8 : 14
                                                    font.bold: true
                                                    font.family: Config.fontFamily
                                                    anchors.centerIn: parent
                                                }
                                            }
                                        }
                                    }
                                }
                            }
                        }
