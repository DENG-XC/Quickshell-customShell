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
        // anchors.topMargin: Config.sc(60)
        spacing: Config.sc(20)
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
                    from: Config.sc(50)
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
            height: Config.sc(110)
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
                        to: Config.sc(100)
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
                radius: Config.sc(25)

                MouseArea {
                    id: mouseArea
                    anchors.fill: parent
                    hoverEnabled: true
                }

                Item {
                    id: notificationContainer
                    anchors.fill: parent
                    anchors.margins: Config.sc(Config.gaps)

                    Item {
                        id: iconContainer
                        width: Config.sc(70)
                        height: Config.sc(70)
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
                            radius: Config.sc(15)
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
                        anchors.leftMargin: Config.sc(Config.gaps)
                        anchors.right: closeButton.left
                        anchors.rightMargin: Config.sc(Config.gaps)
                        anchors.verticalCenter: parent.verticalCenter
                        spacing: Config.sc(5)

                        Text {
                            width: parent.width
                            text: model.appName
                            font.pixelSize: Config.scFont(20)
                            font.bold: true
                            font.family: Config.fontFamily
                            color: Config.text
                            elide: Text.ElideRight
                        }

                        Text {
                            width: parent.width
                            text: model.summary
                            font.pixelSize: Config.scFont(16)
                            font.bold: true
                            font.family: Config.fontFamily
                            color: Config.text
                            opacity: 0.6
                            elide: Text.ElideRight
                            maximumLineCount: 2
                        }
                    }

                    Rectangle {
                        id: closeButton
                        width: Config.sc(22)
                        height: Config.sc(22)
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
                            font.pixelSize: Config.scFont(14)
                            font.bold: true
                            font.family: Config.fontFamily
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
                        font.pixelSize: Config.scFont(10)
                        font.family: Config.fontFamily
                    }
                }
            }
        }
    }
}
