import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Io
import Quickshell.Services.Pipewire
import Quickshell.Widgets

Scope {
    id: root

    PwObjectTracker {
        objects: [Pipewire.defaultAudioSink]
    }

    Connections {
        target: Pipewire.defaultAudioSink ? Pipewire.defaultAudioSink.audio : null

        function onVolumeChanged() {
            root.shouldShowOsd = true;
            hideTimer.restart();
        }
    }

    property bool shouldShowOsd: false
    property int volume: Math.round((Pipewire.defaultAudioSink?.audio.volume ?? 0) * 100)

    Timer {
        id: hideTimer
        interval: 2000
        onTriggered: root.shouldShowOsd = false
    }

    LazyLoader {
        active: root.shouldShowOsd

        PanelWindow {

            anchors.bottom: true
            margins.bottom: Screen.height / 6
            exclusionMode: ExclusionMode.Ignore

            implicitWidth: Screen.width / 10
            implicitHeight: 50
            color: "transparent"

            Rectangle {
                anchors.right: parent.right
                implicitWidth: 50
                implicitHeight: parent.height
                color: Config.background
                radius: height / 2

                Text {
                    id: volumeText
                    text: root.volume
                    anchors.centerIn: parent
                    font.pixelSize: 18
                    font.bold: true
                    font.family: "JetBrains Mono Nerd Font 10"
                    color: Config.text
                }
            }

            Rectangle {
                anchors.left: parent.left
                anchors.top: parent.top
                anchors.bottom: parent.bottom
                implicitWidth: parent.width - 60
                radius: height / 2
                color: Config.background

                RowLayout {
                    anchors {
                        left: parent.left
                        right: parent.right
                        leftMargin: 20
                        rightMargin: 20
                        verticalCenter: parent.verticalCenter
                    }

                    Text {
                        id: volumeicon
                        font.pixelSize: 18
                        font.bold: true
                        font.family: "JetBrains Mono Nerd Font 10"
                        text: {
                            if (root.volume === 0)
                                return "";
                            if (root.volume < 50)
                                return "";
                            return "";
                        }
                        color: Config.text
                        Layout.rightMargin: 10
                    }

                    Rectangle {
                        id: track
                        Layout.fillWidth: true
                        implicitHeight: 10
                        radius: height / 2
                        color: Config.foreground

                        Rectangle {
                            anchors {
                                left: parent.left
                                top: parent.top
                                bottom: parent.bottom
                            }

                            implicitWidth: parent.width * (Pipewire.defaultAudioSink?.audio.volume ?? 0)
                            radius: parent.radius
                            color: Config.textHover
                        }

                        Rectangle {
                            id: handle
                            implicitHeight: parent.height
                            implicitWidth: parent.height
                            radius: height / 2
                            color: "transparent"
                            anchors.verticalCenter: parent.verticalCenter
                            anchors.left: parent.left
                            anchors.leftMargin: (track.width - handle.width) * (Pipewire.defaultAudioSink?.audio.volume ?? 0)
                        }

                        MouseArea {
                            anchors.fill: parent
                            hoverEnabled: true
                            cursorShape: Qt.PointingHandCursor
                            onPositionChanged: if (pressed)
                                setVolume(mouseX)
                            onClicked: setVolume(mouseX)

                            function setVolume(x) {
                                if (!Pipewire.defaultAudioSink)
                                    return;
                                const v = Math.max(0, Math.min(1, x / track.width));
                                Pipewire.defaultAudioSink.audio.volume = v;
                            }
                        }
                    }
                }
            }
        }
    }
}
