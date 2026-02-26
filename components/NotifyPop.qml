import QtQuick
import Qt5Compat.GraphicalEffects

Item {
    id: notifyRoot
    width: parent.width
    height: notifyList.contentHeight

    property var popupModel: null

    ListView {
        id: notifyList
        anchors.top: parent.top
        anchors.left: parent.left
        anchors.right: parent.right
        height: contentHeight
        boundsBehavior: Flickable.StopAtBounds
        // anchors.topMargin: 60
        spacing: 20
        clip: true
        model: popupModel

        add: Transition {
            ParallelAnimation {
                NumberAnimation {
                    property: "opacity"
                    from: 0
                    to: 1
                    duration: 300
                    easing.type: Easing.OutQuad
                }
                NumberAnimation {
                    property: "x"
                    from: 50
                    to: 0
                    duration: 300
                    easing.type: Easing.OutBack
                }
            }
        }

        displaced: Transition {
            NumberAnimation {
                property: "y"
                duration: 300
                easing.type: Easing.InOutQuad
            }
        }

        delegate: Item {
            id: delegateItem
            width: notifyList.width
            height: 110
            opacity: 1

            function close() {
                removeAnim.start();
            }

            SequentialAnimation {
                id: removeAnim
                ParallelAnimation {
                    NumberAnimation {
                        target: delegateItem
                        property: "opacity"
                        to: 0
                        duration: 250
                        easing.type: Easing.InQuad
                    }
                    NumberAnimation {
                        target: delegateItem
                        property: "height"
                        to: 0
                        duration: 250
                        easing.type: Easing.InOutQuad
                    }
                    NumberAnimation {
                        target: bgRect
                        property: "x"
                        to: 100
                        duration: 250
                        easing.type: Easing.InQuad
                    }
                }

                ScriptAction {
                    script: popupModel.remove(index)
                }
            }

            Timer {
                id: closeTimer
                interval: 5000
                running: !mouseArea.containsMouse
                repeat: false
                onTriggered: delegateItem.close()
            }

            Rectangle {
                id: bgRect
                anchors.fill: parent
                color: Config.background
                radius: 25

                MouseArea {
                    id: mouseArea
                    anchors.fill: parent
                    hoverEnabled: true
                }

                Item {
                    id: notificationContainer
                    anchors.fill: parent
                    anchors.margins: 20

                    Item {
                        id: iconContainer
                        width: 70
                        height: 70
                        anchors.left: parent.left
                        anchors.verticalCenter: parent.verticalCenter

                        Image {
                            id: notifyIcon
                            source: model.icon || "../logo/logo.svg"
                            anchors.fill: parent
                            fillMode: Image.PreserveAspectCrop
                            visible: false
                            asynchronous: true
                        }

                        Rectangle {
                            id: maskRect
                            anchors.fill: parent
                            radius: 15
                            visible: false
                        }

                        OpacityMask {
                            anchors.fill: notifyIcon
                            source: notifyIcon
                            maskSource: maskRect
                        }
                    }

                    Column {
                        anchors.left: iconContainer.right
                        anchors.leftMargin: 20
                        anchors.right: closeButton.left
                        anchors.rightMargin: 20
                        anchors.verticalCenter: parent.verticalCenter
                        spacing: 5

                        Text {
                            width: parent.width
                            text: model.appName
                            font.pixelSize: 20
                            font.bold: true
                            font.family: "JetBrains Mono Nerd Font 10"
                            color: Config.text
                            elide: Text.ElideRight
                        }

                        Text {
                            width: parent.width
                            text: model.summary
                            font.pixelSize: 16
                            font.bold: true
                            font.family: "JetBrains Mono Nerd Font 10"
                            color: Config.text
                            opacity: 0.6
                            elide: Text.ElideRight
                            maximumLineCount: 2
                        }
                    }

                    Rectangle {
                        id: closeButton
                        width: 22
                        height: 22
                        anchors.right: parent.right
                        anchors.top: parent.top
                        color: Config.closeColor
                        radius: width / 2
                        opacity: closeMouse.containsMouse ? 1 : 0.6

                        Behavior on opacity {
                            NumberAnimation {
                                duration: 150
                            }
                        }

                        Text {
                            anchors.centerIn: parent
                            text: ""
                            color: Config.background
                            font.pixelSize: 14
                            font.bold: true
                            font.family: "JetBrains Mono Nerd Font 10"
                        }

                        MouseArea {
                            id: closeMouse
                            anchors.fill: parent
                            hoverEnabled: true
                            cursorShape: Qt.PointingHandCursor
                            onClicked: delegateItem.close()
                        }
                    }

                    Text {
                        anchors.right: parent.right
                        anchors.bottom: parent.bottom
                        text: model.time
                        color: Config.text
                        opacity: 0.4
                        font.pixelSize: 10
                        font.family: "JetBrains Mono Nerd Font 10"
                    }
                }
            }
        }
    }
}
