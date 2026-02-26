import QtQuick
import QtQuick.Layouts
import QtQuick.Controls

Rectangle {
    id: calendarRoot
    width: 390
    height: 360
    radius: 25
    color: Config.background

    property var viewDate: new Date()

    function getDaysInMonth(date) {
        return new Date(date.getFullYear(), date.getMonth() + 1, 0).getDate();
    }

    function getFirstDayOffset(date) {
        return new Date(date.getFullYear(), date.getMonth(), 1).getDay();
    }

    function changeMonth(offset) {
        let d = new Date(viewDate);
        d.setMonth(d.getMonth() + offset);
        viewDate = d;
    }

    function resetToToday() {
        viewDate = new Date();
    }

    ColumnLayout {
        anchors.fill: parent
        anchors.margins: 20
        spacing: 20

        RowLayout {
            Layout.fillWidth: true

            Item {
                id: prevButton
                width: 24
                height: 24

                property bool isHovered: false

                Text {
                    text: "❮"
                    color: Config.text
                    anchors.centerIn: parent
                    font.pixelSize: 14
                }

                MouseArea {
                    id: prevMouse
                    anchors.fill: parent
                    hoverEnabled: true
                    cursorShape: Qt.PointingHandCursor
                    onClicked: calendarRoot.changeMonth(-1)
                    onEntered: parent.isHovered = true
                    onExited: parent.isHovered = false
                }

                Rectangle {
                    id: prevRect
                    anchors.fill: parent
                    radius: height / 2
                    color: parent.isHovered ? Config.textHover : "transparent"
                    opacity: parent.isHovered ? 0.3 : 0
                }
            }

            Text {
                Layout.fillWidth: true
                horizontalAlignment: Text.AlignHCenter
                text: Qt.formatDateTime(calendarRoot.viewDate, "MMMM yyyy")
                color: Config.text
                font.bold: true
                font.pixelSize: 18
                font.family: "JetBrains Mono Nerd Font"
            }

            Item {
                width: 24
                height: 24

                property bool isHovered: false

                Text {
                    text: "❯"
                    color: Config.text
                    anchors.centerIn: parent
                    font.pixelSize: 14
                }
                MouseArea {
                    id: nextMouse
                    anchors.fill: parent
                    hoverEnabled: true
                    cursorShape: Qt.PointingHandCursor
                    onClicked: calendarRoot.changeMonth(1)
                    onEntered: parent.isHovered = true
                    onExited: parent.isHovered = false
                }

                Rectangle {
                    id: nextRect
                    anchors.fill: parent
                    radius: height / 2
                    color: parent.isHovered ? Config.textHover : "transparent"
                    opacity: parent.isHovered ? 0.3 : 0
                }
            }
        }

        RowLayout {
            Layout.fillWidth: true
            spacing: 0
            Repeater {
                model: ["Su", "Mo", "Tu", "We", "Th", "Fr", "Sa"]
                delegate: Item {
                    Layout.fillWidth: true
                    height: 20
                    Text {
                        anchors.centerIn: parent
                        text: modelData
                        color: Config.text
                        opacity: 0.6
                        font.pixelSize: 12
                        font.family: "JetBrains Mono Nerd Font"
                    }
                }
            }
        }

        GridLayout {
            columns: 7
            Layout.fillWidth: true
            Layout.fillHeight: true
            columnSpacing: 2
            rowSpacing: 2

            Repeater {
                model: calendarRoot.getFirstDayOffset(calendarRoot.viewDate)
                delegate: Item {
                    Layout.fillWidth: true
                    Layout.fillHeight: true
                }
            }

            Repeater {
                model: calendarRoot.getDaysInMonth(calendarRoot.viewDate)
                delegate: Rectangle {
                    property int dayNum: index + 1
                    property bool isToday: {
                        let now = new Date();
                        return now.getDate() === dayNum && now.getMonth() === calendarRoot.viewDate.getMonth() && now.getFullYear() === calendarRoot.viewDate.getFullYear();
                    }

                    Layout.fillWidth: true
                    //Layout.fillHeight: true
                    Layout.preferredHeight: width
                    radius: height / 2
                    color: isToday ? Config.textHover : "transparent"

                    Text {
                        anchors.centerIn: parent
                        text: dayNum
                        font.bold: isToday
                        color: Config.text
                        font.family: "JetBrains Mono Nerd Font"
                        font.pixelSize: 16
                    }
                }
            }
        }
    }
}
