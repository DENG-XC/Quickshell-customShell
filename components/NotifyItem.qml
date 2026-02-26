import QtQuick
import QtQuick.Controls
import Qt5Compat.GraphicalEffects

Rectangle {
    id: notifyContainer
    radius: 25
    color: Config.background

    Item {
        id: notifyComponent
        width: parent.width
        height: 80

        Text {
            id: notifyText
            text: "Notifications"
            anchors.left: parent.left
            anchors.leftMargin: 30
            anchors.verticalCenter: parent.verticalCenter
            color: Config.text
            font.pixelSize: 22
            font.bold: true
            font.family: "JetBrains Mono Nerd Font 10"
        }

        Rectangle {
            id: cleanButtonBg
            anchors.right: parent.right
            anchors.rightMargin: 30
            anchors.verticalCenter: parent.verticalCenter
            width: 40
            height: width
            radius: width / 2
            color: Config.textHover
            opacity: 0

            Behavior on opacity {
                NumberAnimation {
                    duration: 200
                    easing.type: Easing.InOutQuad
                }
            }

            MouseArea {
                anchors.fill: parent
                cursorShape: Qt.PointingHandCursor
                hoverEnabled: true
                onEntered: {
                    parent.opacity = 0.3;
                }
                onExited: {
                    parent.opacity = 0;
                }
                onClicked: {
                    Config.notificationModel.clear();
                    Config.notify = false;
                }
            }
        }

        Text {
            id: cleanButton
            text: ""
            anchors.centerIn: cleanButtonBg
            color: Config.text
            font.pixelSize: 16
            font.bold: true
            font.family: "JetBrains Mono Nerd Font 10"
        }
    }

    Item {
        id: notificationItem
        anchors.fill: notifyContainer
        visible: (Config.notificationModel ? Config.notificationModel.count === 0 : false) && notificationList.pendingRemovals === 0

        Text {
            id: notificationIcon
            text: ""
            anchors.centerIn: parent
            color: Config.text
            font.pixelSize: 60
            font.bold: true
            font.family: "JetBrains Mono Nerd Font 10"
        }

        Text {
            id: notificationText
            text: "No Notifications"
            anchors.top: notificationIcon.bottom
            anchors.horizontalCenter: parent.horizontalCenter
            anchors.topMargin: 10
            color: Config.text
            font.pixelSize: 22
            font.bold: true
            font.family: "JetBrains Mono Nerd Font 10"
        }
    }

    ScrollView {
        anchors.top: notifyComponent.bottom
        anchors.bottom: parent.bottom
        anchors.left: parent.left
        anchors.right: parent.right
        anchors.bottomMargin: 20
        anchors.leftMargin: 20
        anchors.rightMargin: 5

        ListView {
            id: notificationList
            spacing: 20
            model: Config.notificationModel
            clip: true

            property int pendingRemovals: 0

            add: Transition {
                ParallelAnimation {
                    NumberAnimation {
                        property: "x"
                        from: -width
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

            delegate: Rectangle {
                id: notificationContainer
                width: notificationList.width - 15
                height: notifyExpanded ? expandHeight : collapseHeight
                radius: 25
                color: Config.foreground
                x: 0
                opacity: 1
                clip: true

                property bool removing: false
                property bool dismissHovered: false
                property bool expandHovered: false
                property bool notifyExpanded: false
                property int expandHeight: notificationList.height
                property int collapseHeight: (notificationList.height - 20) / 2

                SequentialAnimation {
                    id: localRemoveAnim
                    running: false

                    ParallelAnimation {
                        NumberAnimation {
                            target: notificationContainer
                            property: "opacity"
                            from: 1
                            to: 0
                            duration: 300
                            easing.type: Easing.InOutQuad
                        }
                        NumberAnimation {
                            target: notificationContainer
                            property: "x"
                            from: 0
                            to: -notificationContainer.width
                            duration: 300
                            easing.type: Easing.InOutQuad
                        }
                    }

                    onFinished: {
                        if (notificationList.pendingRemovals > 0) {
                            notificationList.pendingRemovals--;
                        }
                        Config.notificationModel.remove(index);
                        Config.notify = false;
                    }
                }

                Image {
                    id: notifyIcon
                    source: Config.notificationModel ? (icon || image || "../logo/logo.svg") : ""
                    x: 20
                    y: (((notificationList.height - 20) / 2) - height) / 2
                    height: 60
                    width: height
                    fillMode: Image.PreserveAspectCrop
                    visible: false//parent.notif ? !parent.notif.image : true
                    z: 1
                }

                Rectangle {
                    id: profileBackground
                    anchors.fill: notifyIcon
                    radius: 15
                    visible: Config.notificationModel ? (!image && !icon) : false
                }

                OpacityMask {
                    anchors.fill: notifyIcon
                    source: notifyIcon
                    maskSource: profileBackground
                }

                Text {
                    id: notifyAppName
                    x: notifyExpanded ? 20 : 100
                    y: notifyExpanded ? 100 : ((notificationContainer.height - height) / 2) - 15
                    text: Config.notificationModel ? appName : ""
                    font.pixelSize: 22
                    font.bold: true
                    font.family: "JetBrains Mono Nerd Font 10"
                    color: Config.text
                    wrapMode: Text.NoWrap
                    elide: Text.ElideRight

                    Behavior on x {
                        NumberAnimation {
                            duration: 200
                            easing.type: Easing.InOutQuad
                        }
                    }

                    Behavior on y {
                        NumberAnimation {
                            duration: 200
                            easing.type: Easing.InOutQuad
                        }
                    }
                }

                Text {
                    id: notifySummary
                    anchors.bottom: notifyIcon.bottom
                    anchors.left: notifyIcon.right
                    anchors.leftMargin: 20
                    anchors.right: parent.right
                    anchors.rightMargin: 20
                    text: Config.notificationModel ? summary : ""
                    font.pixelSize: 16
                    font.bold: true
                    font.family: "JetBrains Mono Nerd Font 10"
                    opacity: 0.6
                    height: 20
                    visible: notifyExpanded ? false : true
                    color: Config.text
                    wrapMode: Text.Wrap
                    elide: Text.ElideRight
                }

                ScrollView {
                    anchors.top: notifyAppName.bottom
                    anchors.left: notifyIcon.left
                    anchors.right: dismissButton.right
                    anchors.topMargin: 20
                    anchors.bottom: parent.bottom
                    anchors.bottomMargin: 20
                    clip: true
                    contentWidth: notifyBody.width
                    contentHeight: notifyBody.height
                    visible: notifyExpanded ? true : false

                    Text {
                        id: notifyBody
                        width: notificationList.width - 55
                        text: Config.notificationModel ? body : ""
                        font.pixelSize: 16
                        font.bold: true
                        font.family: "JetBrains Mono Nerd Font 10"
                        color: Config.text
                        opacity: 0.6
                        wrapMode: Text.Wrap
                    }
                }

                Rectangle {
                    id: dot
                    width: 5
                    height: 5
                    radius: height / 2
                    anchors.left: notifyAppName.right
                    anchors.verticalCenter: notifyAppName.verticalCenter
                    anchors.leftMargin: 20
                    color: Config.text
                    visible: notifyExpanded ? true : false
                }

                Text {
                    id: notifyTime
                    anchors.left: dot.right
                    anchors.verticalCenter: notifyAppName.verticalCenter
                    anchors.leftMargin: 20
                    text: Config.notificationModel ? time : ""
                    color: Config.text
                    visible: notifyExpanded ? true : false
                    opacity: 0.6
                    font.pixelSize: 16
                    font.bold: true
                    font.family: "JetBrains Mono Nerd Font 10"
                }

                Rectangle {
                    id: expandedButton
                    y: ((((notificationList.height - 20) / 2) - height) / 2) - 15
                    anchors.right: dismissButton.left
                    anchors.rightMargin: 20
                    width: 20
                    height: width
                    color: Config.expandedColor
                    opacity: expandHovered ? 1 : 0.6
                    radius: height / 2

                    Behavior on opacity {
                        NumberAnimation {
                            duration: 200
                            easing.type: Easing.InOutQuad
                        }
                    }

                    Text {
                        id: expandIcon
                        anchors.centerIn: parent
                        text: ""
                        rotation: notifyExpanded ? 180 : 0
                        color: Config.background
                        font.pixelSize: 16
                        font.bold: true
                        font.family: "JetBrains Mono Nerd Font 10"

                        Behavior on rotation {
                            NumberAnimation {
                                duration: 200
                                easing.type: Easing.InOutQuad
                            }
                        }
                    }

                    MouseArea {
                        anchors.fill: parent
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
                        onClicked: {
                            notifyExpanded = !notifyExpanded;
                        }
                        onEntered: {
                            expandHovered = true;
                        }
                        onExited: {
                            expandHovered = false;
                        }
                    }
                }

                Rectangle {
                    id: dismissButton
                    y: ((((notificationList.height - 20) / 2) - height) / 2) - 15
                    anchors.right: parent.right
                    anchors.rightMargin: 20
                    width: 20
                    height: width
                    color: Config.closeColor
                    opacity: dismissHovered ? 1 : 0.6
                    radius: height / 2

                    Behavior on opacity {
                        NumberAnimation {
                            duration: 200
                            easing.type: Easing.InOutQuad
                        }
                    }

                    Text {
                        anchors.centerIn: parent
                        text: ""
                        color: Config.background
                        font.pixelSize: 16
                        font.bold: true
                        font.family: "JetBrains Mono Nerd Font 10"
                    }

                    MouseArea {
                        anchors.fill: parent
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
                        onClicked: {
                            if (!notificationContainer.removing) {
                                notificationContainer.removing = true;
                                notificationList.pendingRemovals += 1;
                                localRemoveAnim.start();
                            }
                        }
                        onEntered: {
                            dismissHovered = true;
                        }
                        onExited: {
                            dismissHovered = false;
                        }
                    }
                }
            }
        }
    }
}
