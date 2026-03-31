import QtQuick
import QtQuick.Layouts

Item {
    id: bottomContainer
    Layout.preferredWidth: parent.width
    Layout.preferredHeight: leftPanel.collapsed ? pinIcon.height + collapsedIcon.height + Config.sc(20) : Math.round(parent.height / 50)
    Layout.fillHeight: false

    Text {
        id: pinIcon
        text: ""
        x: leftPanel.collapsed ? parent.width / 2 - width / 2 : parent.width - width
        y: leftPanel.collapsed ? parent.height - height : parent.height / 2 - height / 2
        color: leftPanel.ispin ? Config.textHover : Config.text
        font.pixelSize: Config.scFont(22)
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
                let targetWidth = leftPanel.ispin ? (leftPanel.collapsed ? Config.sc(60) : leftPanel.panelwidth) : 0;

                // 使用专门的 struts 脚本（更快，只修改 struts 部分）
                Buttoncommand.setStrutsExec(targetWidth);
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
        font.pixelSize: Config.scFont(22)
        font.bold: true
        font.family: Config.fontFamily

        MouseArea {
            anchors.fill: parent
            enabled: true
            cursorShape: Qt.PointingHandCursor
            onClicked: {
                leftPanel.collapsed = !leftPanel.collapsed;
                let targetWidth = leftPanel.collapsed ? (leftPanel.ispin ? Config.sc(60) : 0) : leftPanel.ispin ? leftPanel.panelwidth : 0;

                // 使用专门的 struts 脚本（更快，只修改 struts 部分）
                Buttoncommand.setStrutsExec(targetWidth);
            }
        }
    }
}
