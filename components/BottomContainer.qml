import QtQuick
import QtQuick.Layouts

Item {
                            id: bottomContainer
                            Layout.preferredWidth: parent.width
                            Layout.preferredHeight: leftPanel.collapsed ? pinIcon.height + collapsedIcon.height + 20 : Math.round(parent.height / 50)
                            Layout.fillHeight: false

                            Text {
                                id: pinIcon
                                text: ""
                                x: leftPanel.collapsed ? parent.width / 2 - width / 2 : parent.width - width
                                y: leftPanel.collapsed ? parent.height - height : parent.height / 2 - height / 2
                                color: leftPanel.ispin ? Config.textHover : Config.text
                                font.pixelSize: 22
                                font.bold: true
                                font.family: Config.fontFamily

                                Behavior on color {
                                    PropertyAnimation {
                                        duration: 200
                                        easing.type: Easing.InOutQuad
                                    }
                                }

                                MouseArea {
                                    anchors.fill: parent
                                    enabled: true
                                    cursorShape: Qt.PointingHandCursor
                                    onClicked: {
                                        leftPanel.ispin = !leftPanel.ispin;
                                    }
                                }
                            }

                            Text {
                                id: collapsedIcon
                                text: ""
                                rotation: leftPanel.collapsed ? 0 : 180
                                x: leftPanel.collapsed ? parent.width / 2 - width / 2 : 0
                                y: leftPanel.collapsed ? 0 : parent.height / 2 - height / 2
                                color: Config.text
                                font.pixelSize: 22
                                font.bold: true
                                font.family: Config.fontFamily

                                MouseArea {
                                    anchors.fill: parent
                                    enabled: true
                                    cursorShape: Qt.PointingHandCursor
                                    onClicked: {
                                        leftPanel.collapsed = !leftPanel.collapsed;
                                    }
                                }
                            }
                        }