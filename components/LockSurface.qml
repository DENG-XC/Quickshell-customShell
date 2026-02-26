import QtQuick
import QtQuick.Layouts
import QtQuick.Controls
import Quickshell.Services.Pam

Item {
    id: lockSurface
    anchors.fill: parent

    property bool verifying: false

    ParallelAnimation {
        id: errorAnimation

        SequentialAnimation {

            ScriptAction {
                script: contentTranslate.x = 0
            }

            NumberAnimation {
                target: contentTranslate
                property: "x"
                from: 0
                to: -10
                duration: 50
                easing.type: Easing.OutQuad
            }

            NumberAnimation {
                target: contentTranslate
                property: "x"
                from: -10
                to: 10
                duration: 50
                easing.type: Easing.OutQuad
            }

            NumberAnimation {
                target: contentTranslate
                property: "x"
                from: 10
                to: -10
                duration: 50
                easing.type: Easing.OutQuad
            }

            NumberAnimation {
                target: contentTranslate
                property: "x"
                from: -10
                to: 10
                duration: 50
                easing.type: Easing.OutQuad
            }

            NumberAnimation {
                target: contentTranslate
                property: "x"
                from: 10
                to: 0
                duration: 50
                easing.type: Easing.OutQuad
            }
        }

        SequentialAnimation {
            ColorAnimation {
                target: passwordBackground
                property: "color"
                from: Config.text
                to: "red"
                duration: 0
                easing.type: Easing.OutQuad
            }

            ColorAnimation {
                target: passwordBackground
                property: "color"
                from: "red"
                to: Config.text
                duration: 400
                easing.type: Easing.OutQuad
            }
        }
    }

    PamContext {
        id: pam
        configDirectory: "../pam"
        config: "password.conf"

        onPamMessage: {
            if (responseRequired) {
                respond(passwordField.text);
            }
        }

        onCompleted: result => {
            lockSurface.verifying = false;

            if (result === PamResult.Success) {
                root.unlock = false;
                Qt.quit();
            } else {
                passwordField.text = "";
                passwordField.placeholderText = "Incorrect password";
                errorAnimation.start();
            }
        }
    }

    Image {
        id: lockBackground
        anchors.fill: parent
        sourceSize.width: parent.width
        sourceSize.height: parent.height
        source: "../wallpaper/backgroundblur.jpg"
        fillMode: Image.PreserveAspectCrop
        z: -1
    }

    ColumnLayout {
        id: lockContent
        anchors.centerIn: parent
        spacing: 20

        Image {
            id: userIcon
            width: 100
            height: 100
            sourceSize.height: 100
            sourceSize.width: 100
            source: "../logo/user.svg"
            fillMode: Image.PreserveAspectFit
            Layout.alignment: Qt.AlignHCenter
        }

        Item {
            id: userNamerContainer
            implicitWidth: userName.width
            implicitHeight: userName.height
            Layout.alignment: Qt.AlignHCenter

            Text {
                id: userName
                text: root.userName
                font.pixelSize: 30
                font.bold: true
                font.family: Config.fontFamily
                color: Config.text
                anchors.centerIn: parent
            }
        }

        Item {
            id: passwordLayout
            Layout.alignment: Qt.AlignHCenter
            implicitWidth: passwordBackground.width
            implicitHeight: 40

            transform: Translate {
                id: contentTranslate
            }

            Rectangle {
                id: passwordBackground
                color: Config.text
                height: 40
                width: 200
                opacity: 0.2
                radius: height / 2
            }

            TextField {
                id: passwordField
                background: Rectangle {
                    color: "transparent"
                }
                placeholderText: "Enter Password"
                placeholderTextColor: Config.text
                anchors.fill: passwordBackground
                anchors.leftMargin: 10
                color: Config.text
                focus: true
                font.pixelSize: 16
                font.bold: true
                font.family: Config.fontFamily
                inputMethodHints: Qt.ImhHiddenText | Qt.ImhNoPredictiveText | Qt.ImhSensitiveData | Qt.ImhNoAutoUppercase
                echoMode: TextInput.Password
                enabled: !lockSurface.verifying

                onAccepted: {
                    if (text.length > 0) {
                        lockSurface.verifying = true;
                        pam.start();
                    }
                }
                onTextChanged: {
                    if (text.length > 0 && !lockSurface.verifying) {
                        placeholderText = "Enter Password";
                    }
                }
            }

            Item {
                id: passwordIcon
                width: 40
                height: 40
                anchors.left: passwordField.right
                anchors.leftMargin: 20

                Item {
                    id: lockIcon
                    anchors.fill: parent
                    visible: !lockSurface.verifying

                    Rectangle {
                        id: unlockButton
                        anchors.fill: parent
                        radius: height / 2
                        color: Config.text
                        opacity: 0.2

                        MouseArea {
                            anchors.fill: parent
                            cursorShape: Qt.PointingHandCursor
                            onClicked: {
                                if (passwordField.text.length > 0) {
                                    lockSurface.verifying = true;
                                    pam.start();
                                }
                            }
                        }
                    }

                    Text {
                        text: ""
                        font.pixelSize: 16
                        font.bold: true
                        font.family: Config.fontFamily
                        color: Config.text
                        anchors.centerIn: parent
                    }
                }

                Item {
                    id: loadingIcon
                    anchors.fill: parent
                    visible: lockSurface.verifying

                    Text {
                        text: ""
                        font.pixelSize: 20
                        font.bold: true
                        font.family: Config.fontFamily
                        color: Config.text
                        anchors.centerIn: parent
                    }

                    RotationAnimation {
                        target: loadingIcon
                        from: 0
                        to: 360
                        duration: 1000
                        loops: Animation.Infinite
                        running: lockSurface.verifying
                    }
                }
            }
        }
    }
}
