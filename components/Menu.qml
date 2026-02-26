import QtQuick
import QtQuick.Controls
import QtQuick.Layouts

Rectangle {
                            id: menu
                            color: Config.foreground
                            Layout.preferredWidth: parent.width
                            Layout.preferredHeight: Math.round(parent.height / 3)
                            Layout.alignment: Qt.AlignTop
                            Layout.fillHeight: false
                            radius: 25
                            clip: true
                            visible: leftPanel.collapsed ? false : true

                            property int menuWidth: menu.width - 20
                            property var componentMap: ({
                                    "weather": weatherItem,
                                    "media": mediaItem,
                                    "notify": notifyItem,
                                    "performance": performanceItem
                                })
                            property string currentPageId: "media"

                            ListModel {
                                id: menuModel
                                ListElement {
                                    icon: ""
                                    pageId: "media"
                                }
                                ListElement {
                                    icon: ""
                                    pageId: "weather"
                                }
                                ListElement {
                                    icon: ""
                                    pageId: "notify"
                                }
                                ListElement {
                                    icon: ""
                                    pageId: "performance"
                                }
                            }

                            StackView {
                                id: stackView
                                initialItem: mediaItem
                                anchors.top: buttonBackground.bottom
                                anchors.bottom: parent.bottom
                                width: menu.menuWidth
                                anchors.topMargin: 10
                                anchors.bottomMargin: 10
                                anchors.horizontalCenter: parent.horizontalCenter
                            }

                            Component {
                                id: mediaItem
                                MediaComponent {
                                    id: mediaComponent
                                }
                            }

                            Component {
                                id: performanceItem
                                PerformanceComponent {
                                    id: performanceComponent
                                }
                            }

                            Component {
                                id: notifyItem
                                NotifyItem {
                                    id: notifyItem
                                }
                            }

                            Component {
                                id: weatherItem
                                Rectangle {
                                    id: weatherContainer
                                    color: Config.background
                                    radius: 25

                                    Weather {
                                        id: weatherWidget
                                    }
                                }
                            }

                            Rectangle {
                                id: buttonBackground
                                anchors.top: parent.top
                                anchors.topMargin: 10
                                anchors.horizontalCenter: parent.horizontalCenter
                                width: menu.menuWidth
                                height: parent.height / 5
                                color: Config.background
                                radius: 25

                                RowLayout {
                                    id: buttonLayout
                                    anchors.top: parent.top
                                    anchors.topMargin: 10
                                    anchors.bottom: parent.bottom
                                    anchors.bottomMargin: 10
                                    anchors.horizontalCenter: parent.horizontalCenter
                                    width: menu.menuWidth
                                    spacing: 0
                                    Repeater {
                                        model: menuModel
                                        delegate: Item {
                                            id: menuItem
                                            Layout.fillWidth: true
                                            Layout.fillHeight: true

                                            property bool hovered: false
                                            property bool selected: pageId === menu.currentPageId

                                            Text {
                                                id: iconText
                                                text: icon
                                                anchors.centerIn: parent
                                                color: Config.text
                                                font.pixelSize: 22
                                                font.bold: true
                                                opacity: (menuItem.hovered || menuItem.selected) ? 1 : 0.6
                                                font.family: Config.fontFamily

                                                Behavior on opacity {
                                                    NumberAnimation {
                                                        duration: 300
                                                        easing.type: Easing.InOutQuad
                                                    }
                                                }

                                                MouseArea {
                                                    anchors.fill: parent
                                                    hoverEnabled: true
                                                    cursorShape: Qt.PointingHandCursor
                                                    onEntered: {
                                                        menuItem.hovered = true;
                                                    }
                                                    onExited: {
                                                        menuItem.hovered = false;
                                                    }
                                                    onClicked: {
                                                        let component = menu.componentMap[pageId];
                                                        if (component) {
                                                            stackView.replace(component);
                                                        }
                                                        menu.currentPageId = pageId;
                                                    }
                                                }
                                            }

                                            Rectangle {
                                                id: focusLine
                                                anchors.top: iconText.bottom
                                                anchors.horizontalCenter: parent.horizontalCenter
                                                anchors.topMargin: 5
                                                width: menuItem.selected ? 22 : 0
                                                height: 5
                                                color: Config.text
                                                radius: height / 2

                                                Behavior on width {
                                                    NumberAnimation {
                                                        duration: 300
                                                        easing.type: Easing.InOutQuad
                                                    }
                                                }
                                            }
                                        }
                                    }
                                }
                            }
                        }
