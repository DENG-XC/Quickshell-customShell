import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Io
import Quickshell.Services.SystemTray

Rectangle {
    id: topbarcontainer
    width: parent.width
    height: Config.sc(Config.topbarwidth)
    color: Config.background
    z: 1

    property ListModel buttons: leftbuttons

    readonly property var process: Process {}

    function exec(command) {
        process.exec(["bash", "-c", command]);
    }

    ListModel {
        id: leftbuttons
        ListElement {
            icon: ""
            command: "niri msg action toggle-overview"
        }
        ListElement {
            icon: ""
            command: "hyprpicker -a"
        }
        ListElement {
            icon: ""
            command: "niri msg action screenshot"
        }
        ListElement {
            icon: ""
            command: ""
        }
    }

    Item {
        id: clockContainer
        anchors.centerIn: parent
        height: Config.sc(30)
        width: clock.width + Config.sc(40)
        z: 2

        Text {
            id: clock
            anchors.centerIn: parent
            text: Clock.time
            font.pixelSize: Config.scFont(18)
            color: Config.text
            font.bold: true
            font.family: Config.fontFamily
            z: 1
        }

        Rectangle {
            anchors.fill: parent
            color: Config.textHover
            radius: height / 2
            opacity: hovered ? 0.3 : 0

            property bool hovered: false

            Behavior on opacity {
                NumberAnimation {
                    easing.type: Easing.InOutQuad
                    duration: 200
                }
            }

            MouseArea {
                anchors.fill: parent
                hoverEnabled: true
                cursorShape: Qt.PointingHandCursor
                onEntered: parent.hovered = true
                onExited: parent.hovered = false
                onClicked: {
                    Config.calendarVisible = !Config.calendarVisible;
                }
            }
        }
    }

    RowLayout {
        id: topbarlayout
        anchors.fill: parent
        anchors.leftMargin: Config.sc(20)
        anchors.rightMargin: Config.sc(20)

        Row {
            spacing: Config.sc(10)

            Repeater {
                model: buttons
                delegate: Rectangle {
                    id: leftButtonsContainer
                    width: Config.sc(50)
                    height: Config.sc(30)
                    color: "transparent"

                    property bool hover: false

                    Text {
                        id: leftButtonIcon
                        anchors.centerIn: parent
                        text: icon
                        color: Config.text
                        font.pixelSize: Config.scFont(20)
                        font.bold: true
                        font.family: Config.fontFamily
                        z: 1
                    }

                    MouseArea {
                        anchors.fill: parent
                        enabled: true
                        hoverEnabled: true
                        onEntered: {
                            parent.hover = true;
                        }
                        onExited: {
                            parent.hover = false;
                        }
                        cursorShape: Qt.PointingHandCursor
                        onClicked: {
                            if (model.icon === "") {
                                Config.clipboardVisible = true;
                                Config.toggleClipboard = true;
                            } else {
                                topbarcontainer.exec(command);
                            }
                        }
                    }

                    Rectangle {
                        anchors.fill: parent
                        color: Config.textHover
                        radius: height / 2
                        opacity: parent.hover ? 0.3 : 0

                        Behavior on opacity {
                            NumberAnimation {
                                easing.type: Easing.InOutQuad
                                duration: 200
                            }
                        }
                    }
                }
            }
        }

        Item {
            Layout.fillWidth: true
        }

        Row {
            spacing: Config.sc(10)

            Repeater {
                model: SystemTray.items
                delegate: Rectangle {
                    id: trayItem
                    width: Config.sc(50)
                    height: Config.sc(30)
                    color: "transparent"

                    property bool hover: false

                    Image {
                        anchors.centerIn: parent
                        width: Config.sc(20)
                        height: Config.sc(20)
                        source: {
                            let id = modelData.id;
                            let iconName = modelData.icon.toString();
                            if (id === "Fcitx") {
                                if (iconName.indexOf("pinyin") !== -1) {
                                    return "../logo/pinyin.svg";
                                } else {
                                    return "../logo/eng.svg";
                                }
                            }
                            return modelData.icon;
                        }

                        fillMode: Image.PreserveAspectFit
                        z: 1
                    }

                    MouseArea {
                        anchors.fill: parent
                        cursorShape: Qt.PointingHandCursor
                        hoverEnabled: true
                        onEntered: parent.hover = true
                        onExited: parent.hover = false
                        acceptedButtons: Qt.LeftButton | Qt.RightButton

                        onClicked: mouse => {
                            if (mouse.button === Qt.LeftButton) {
                                modelData.activate();
                            }
                        }
                    }

                    Rectangle {
                        anchors.fill: parent
                        color: Config.textHover
                        radius: height / 2
                        opacity: parent.hover ? 0.3 : 0

                        Behavior on opacity {
                            NumberAnimation {
                                easing.type: Easing.InOutQuad
                                duration: 200
                            }
                        }
                    }
                }
            }
        }

        Item {
            Layout.preferredWidth: Config.sc(50)
            Layout.preferredHeight: Config.sc(30)

            property bool hover: false

            Text {
                id: powerButton
                text: ""
                anchors.centerIn: parent
                color: Config.text
                font.pixelSize: Config.scFont(20)
                font.bold: true
                font.family: Config.fontFamily
                z: 1
            }

            Rectangle {
                anchors.fill: parent
                color: Config.textHover
                radius: height / 2
                opacity: parent.hover ? 0.3 : 0

                Behavior on opacity {
                    NumberAnimation {
                        easing.type: Easing.InOutQuad
                        duration: 200
                    }
                }
            }

            MouseArea {
                id: overviewTrigger
                anchors.fill: parent
                hoverEnabled: true
                enabled: true
                cursorShape: Qt.PointingHandCursor
                onClicked: {
                    Config.logoutVisible = !Config.logoutVisible;
                }
                onEntered: {
                    parent.hover = true;
                }
                onExited: {
                    parent.hover = false;
                }
            }
        }
    }
}
