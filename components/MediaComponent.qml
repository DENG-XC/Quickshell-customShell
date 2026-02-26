import QtQuick
import QtQuick.Layouts
import Quickshell.Services.Mpris
import Qt5Compat.GraphicalEffects

Rectangle {
    color: Config.background
    radius: 25

    property bool hasArt: mpris && mpris.trackArtUrl !== ""
    property var mpris: null
    property bool hasActivePlayer: false
    property bool volumeActive: false

    function updateMpris() {
        let players = Mpris.players.values;

        if (players.length > 0) {
            let activePlayer = null;

            for (let i = 0; i < players.length; i++) {
                let player = players[i];
                if (player && player.playbackState == MprisPlaybackState.Playing) {
                    activePlayer = player;
                    break;
                }
            }
            hasActivePlayer = activePlayer ? true : false;
            mpris = activePlayer ? activePlayer : players[0];
        } else {
            mpris = null;
        }
    }

    Component.onCompleted: {
        updateMpris();
    }

    Connections {
        target: Mpris.players
        function onValuesChanged() {
            updateMpris();
        }
    }

    Connections {
        target: mpris
        function onPlaybackStateChanged() {
            updateMpris();
        }
    }

    Rectangle {
        id: imageContainer
        height: 180
        anchors.top: parent.top
        anchors.left: parent.left
        anchors.right: parent.right
        anchors.rightMargin: 100
        anchors.leftMargin: ((columnLayout.width - (columnLayout.height / 4)) / 2) + 13
        anchors.topMargin: 20
        radius: 25
        visible: false
    }

    Image {
        id: mprisImage
        visible: false
        anchors.fill: imageContainer
        source: hasArt ? mpris.trackArtUrl : "../logo/music.svg"
        fillMode: hasArt ? Image.PreserveAspectCrop : Image.PreserveAspectFit
        cache: false
        sourceSize.width: width
        sourceSize.height: height
    }

    OpacityMask {
        anchors.fill: imageContainer
        source: mprisImage
        maskSource: imageContainer
    }

    ColorOverlay {
        anchors.fill: mprisImage
        source: mprisImage
        color: Config.text
        visible: !hasArt
    }

    Item {
        id: songName
        anchors.top: imageContainer.bottom
        anchors.topMargin: 20
        anchors.right: imageContainer.right
        anchors.left: parent.left
        anchors.leftMargin: ((columnLayout.width - (columnLayout.height / 4)) / 2) + 13
        height: 22

        Text {
            text: mpris ? mpris.trackTitle : "No Title"
            color: Config.text
            anchors.left: parent.left
            width: parent.width
            font.pixelSize: 22
            font.bold: true
            font.family: Config.fontFamily
            wrapMode: Text.NoWrap
            elide: Text.ElideRight
        }
    }

    Item {
        id: artistName
        anchors.top: songName.bottom
        anchors.topMargin: 20
        anchors.right: songName.right
        anchors.left: songName.left
        height: 22

        Text {
            text: mpris ? (mpris.trackArtists ? mpris.trackArtist : "No Artist") : "No Artist"
            color: Config.text
            anchors.left: parent.left
            width: parent.width
            font.pixelSize: 16
            font.bold: true
            font.family: Config.fontFamily
            wrapMode: Text.NoWrap
            elide: Text.ElideRight
        }
    }

    Item {
        id: songPosition
        anchors.top: artistName.bottom
        anchors.left: artistName.left
        anchors.bottom: parent.bottom
        anchors.right: parent.right
        anchors.rightMargin: ((columnLayout.width - (columnLayout.height / 4)) / 2) + 13

        property bool isDragging: false
        property real dragRatio: 0.0

        Rectangle {
            id: track
            anchors.centerIn: parent
            width: parent.width
            height: 10
            color: Config.foreground
            radius: height / 2
        }

        Rectangle {
            anchors.verticalCenter: parent.verticalCenter
            height: 10
            width: (songPosition.isDragging ? songPosition.dragRatio : (mpris && mpris.length > 0 ? mpris.position / mpris.length : 0)) * parent.width
            color: Config.textHover
            radius: height / 2
        }

        MouseArea {
            anchors.fill: track
            cursorShape: Qt.PointingHandCursor

            onPressed: function (mouse) {
                songPosition.isDragging = true;
                songPosition.dragRatio = Math.max(0, Math.min(1, mouse.x / width));
            }

            onPositionChanged: function (mouse) {
                if (songPosition.isDragging) {
                    songPosition.dragRatio = Math.max(0, Math.min(1, mouse.x / width));
                }
            }

            onReleased: function (mouse) {
                if (songPosition.isDragging && mpris && mpris.length > 0) {
                    songPosition.isDragging = false;
                    let newPos = songPosition.dragRatio * mpris.length;
                    mpris.position = newPos;
                }
            }

            onClicked: function (mouse) {
                if (mpris && mpris.length > 0) {
                    let ratio = Math.max(0, Math.min(1, mouse.x / width));
                    let newPos = ratio * mpris.length;
                    mpris.position = newPos;
                }
            }
        }
    }

    Item {
        id: position
        anchors.right: songPosition.right
        anchors.top: artistName.top
        anchors.bottom: artistName.bottom
        width: implicitWidth

        function formatTime(ms) {
            let seconds = Math.floor(ms % 60);
            let minutes = Math.floor(ms / 60);
            let hours = Math.floor(minutes / 60);
            minutes %= 60;
            if (hours > 0) {
                return hours + ":" + (minutes < 10 ? "0" + minutes : minutes) + ":" + (seconds < 10 ? "0" + seconds : seconds);
            }
            return minutes + ":" + (seconds < 10 ? "0" + seconds : seconds);
        }

        Timer {
            running: hasActivePlayer ? true : false
            interval: 1000
            repeat: true
            onTriggered: mpris.positionChanged()
        }

        Text {
            text: mpris ? position.formatTime(mpris.position) : "0:00"
            anchors.right: parent.right
            font.pixelSize: 16
            color: Config.text
            font.bold: true
            font.family: Config.fontFamily
        }
    }

    Rectangle {
        id: volumeIndicator
        anchors.bottom: columnLayout.bottom
        anchors.bottomMargin: columnLayout.height / 4 + 13
        anchors.horizontalCenter: columnLayout.horizontalCenter
        height: 0
        width: columnLayout.height / 4
        color: Config.foreground
        radius: width / 2

        property bool isVolumeDragging: false
        property real dragRatio: 0.0

        Rectangle {
            id: volumeTrack
            anchors.horizontalCenter: parent.horizontalCenter
            anchors.top: parent.top
            anchors.topMargin: 15
            anchors.bottom: parent.bottom
            anchors.bottomMargin: 15
            width: 10
            color: Config.background
            radius: width / 2
        }

        Rectangle {
            anchors.horizontalCenter: volumeTrack.horizontalCenter
            anchors.bottom: volumeTrack.bottom
            width: 10
            radius: width / 2
            color: Config.textHover
            height: (mpris && mpris.volumeSupported) ? mpris.volume * volumeTrack.height : 0
        }

        MouseArea {
            anchors.fill: volumeTrack
            cursorShape: Qt.PointingHandCursor

            onPressed: function (mouse) {
                parent.isVolumeDragging = true;
                let ratio = Math.max(0, Math.min(1, 1 - (mouse.y / volumeTrack.height)));
                if (mpris && mpris.volumeSupported) {
                    mpris.volume = ratio;
                }
            }

            onPositionChanged: function (mouse) {
                if (parent.isVolumeDragging && mpris && mpris.volumeSupported) {
                    let ratio = Math.max(0, Math.min(1, 1 - (mouse.y / volumeTrack.height)));
                    mpris.volume = ratio;
                }
            }

            onReleased: function () {
                parent.isVolumeDragging = false;
            }

            onClicked: function (mouse) {
                if (mpris && mpris.volumeSupported) {
                    let ratio = Math.max(0, Math.min(1, 1 - (mouse.y / volumeTrack.height)));
                    mpris.volume = ratio;
                }
            }
        }
    }

    ColumnLayout {
        id: columnLayout
        anchors.right: parent.right
        anchors.left: imageContainer.right
        anchors.top: imageContainer.top
        anchors.bottom: imageContainer.bottom
        spacing: 0

        SequentialAnimation {
            id: volumeActiveAnimation
            running: volumeActive

            ParallelAnimation {
                NumberAnimation {
                    target: playerStatusIcon
                    property: "opacity"
                    from: 1
                    to: 0
                    duration: 200
                }
                NumberAnimation {
                    target: previousIcon
                    property: "opacity"
                    from: 1
                    to: 0
                    duration: 200
                }
                NumberAnimation {
                    target: nextIcon
                    property: "opacity"
                    from: 1
                    to: 0
                    duration: 200
                }
            }

            PauseAnimation {
                duration: 50
            }

            NumberAnimation {
                target: volumeIndicator
                property: "height"
                from: 0
                to: columnLayout.height - (columnLayout.height / 4 + 13)
                duration: 200
            }
        }

        SequentialAnimation {
            id: volumeCloseAnimation
            running: !volumeActive

            NumberAnimation {
                target: volumeIndicator
                property: "height"
                from: columnLayout.height - (columnLayout.height / 4 + 13)
                to: 0
                duration: 200
            }

            PauseAnimation {
                duration: 50
            }

            ParallelAnimation {
                NumberAnimation {
                    target: playerStatusIcon
                    property: "opacity"
                    from: 0
                    to: 1
                    duration: 200
                }
                NumberAnimation {
                    target: previousIcon
                    property: "opacity"
                    from: 0
                    to: 1
                    duration: 200
                }
                NumberAnimation {
                    target: nextIcon
                    property: "opacity"
                    from: 0
                    to: 1
                    duration: 200
                }
            }
        }

        Component.onCompleted: {
            imageContainer.anchors.leftMargin = ((columnLayout.width - (columnLayout.height / 4)) / 2) + 13;
        }

        Item {
            id: playerStatusIcon
            Layout.fillWidth: true
            Layout.fillHeight: true
            Layout.alignment: Qt.AlignHCenter
            opacity: 0

            Text {
                id: playerIcon
                text: hasActivePlayer ? "" : ""
                color: Config.text
                anchors.centerIn: parent
                font.pixelSize: 22
                font.bold: true
                font.family: Config.fontFamily
                z: 1
            }

            Rectangle {
                id: playPauseBackground
                width: height
                height: parent.height
                color: Config.textHover
                opacity: 0
                radius: height / 2
                anchors.centerIn: parent

                Behavior on opacity {
                    NumberAnimation {
                        duration: 200
                        easing.type: Easing.InOutQuad
                    }
                }

                MouseArea {
                    enabled: volumeActive ? false : true
                    anchors.fill: parent
                    hoverEnabled: true
                    cursorShape: Qt.PointingHandCursor
                    onClicked: {
                        hasActivePlayer ? mpris.pause() : mpris.play();
                    }
                    onEntered: {
                        parent.opacity = 0.3;
                    }
                    onExited: {
                        parent.opacity = 0;
                    }
                }
            }
        }

        Item {
            id: previousIcon
            Layout.fillWidth: true
            Layout.fillHeight: true
            Layout.alignment: Qt.AlignHCenter
            opacity: 0

            Text {
                text: ""
                color: Config.text
                anchors.centerIn: parent
                font.pixelSize: 22
                font.bold: true
                font.family: Config.fontFamily
                z: 1
            }

            Rectangle {
                width: height
                height: parent.height
                color: Config.textHover
                opacity: 0
                radius: height / 2
                anchors.centerIn: parent

                Behavior on opacity {
                    NumberAnimation {
                        duration: 200
                        easing.type: Easing.InOutQuad
                    }
                }

                MouseArea {
                    enabled: volumeActive ? false : true
                    anchors.fill: parent
                    hoverEnabled: true
                    cursorShape: Qt.PointingHandCursor
                    onClicked: {
                        if (hasActivePlayer) {
                            mpris.previous();
                        }
                    }
                    onEntered: {
                        parent.opacity = 0.3;
                    }
                    onExited: {
                        parent.opacity = 0;
                    }
                }
            }
        }

        Item {
            id: nextIcon
            Layout.fillWidth: true
            Layout.fillHeight: true
            Layout.alignment: Qt.AlignHCenter
            opacity: 0

            Text {
                text: ""
                color: Config.text
                anchors.centerIn: parent
                font.pixelSize: 22
                font.bold: true
                font.family: Config.fontFamily
                z: 1
            }

            Rectangle {
                width: height
                height: parent.height
                color: Config.textHover
                opacity: 0
                radius: height / 2
                anchors.centerIn: parent

                Behavior on opacity {
                    NumberAnimation {
                        duration: 200
                        easing.type: Easing.InOutQuad
                    }
                }

                MouseArea {
                    enabled: volumeActive ? false : true
                    anchors.fill: parent
                    hoverEnabled: true
                    cursorShape: Qt.PointingHandCursor
                    onClicked: {
                        if (hasActivePlayer) {
                            mpris.next();
                        }
                    }
                    onEntered: {
                        parent.opacity = 0.3;
                    }
                    onExited: {
                        parent.opacity = 0;
                    }
                }
            }
        }

        Item {
            Layout.fillWidth: true
            Layout.fillHeight: true
            Layout.alignment: Qt.AlignHCenter

            Text {
                text: ""
                color: Config.text
                anchors.centerIn: parent
                font.pixelSize: 22
                font.bold: true
                font.family: Config.fontFamily
                z: 1
            }

            Rectangle {
                width: height
                height: parent.height
                color: Config.textHover
                opacity: 0
                radius: height / 2
                anchors.centerIn: parent

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
                    onClicked: {
                        volumeActive = !volumeActive;
                        if (volumeActive) {
                            parent.opacity = 1;
                        }
                    }
                    onEntered: {
                        if (!volumeActive) {
                            parent.opacity = 0.3;
                        }
                    }
                    onExited: {
                        if (!volumeActive) {
                            parent.opacity = 0;
                        }
                    }
                }
            }
        }
    }
}
