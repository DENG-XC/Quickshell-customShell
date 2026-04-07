import QtQuick
import QtQuick.Layouts
import QtQuick.Controls
import Quickshell
import Quickshell.Io
import Quickshell.Wayland
import Qt5Compat.GraphicalEffects

FloatingWindow {
    id: configPanel
    title: "settings"
    minimumSize: Qt.size(Config.sc(900), Config.sc(650))
    color: "transparent"

    property int currentPanel: 0
    property var wallPaperModel: []
    property var bluetoothModel: []
    property var connectedModel: []
    property var wifiList: []
    property var wifiConnected: []
    property var monitors: []
    property int selectedWallpaperIndex: 0

    screen: {
        for (let i = 0; i < Quickshell.screens.length; i++) {
            if (Quickshell.screens[i].name === Config.priScreen) {
                return Quickshell.screens[i];
            }
        }
        return Quickshell.screens[0];
    }

    
    onVisibleChanged: {
        if (!visible) {
            Config.configPanelVisible = false;
        }
        if (visible) {
            bluetoothList.running = true;
            wifiList.running = true;
        }
    }

    Process {
        id: wifiList
        command: ["nmcli", "-t", "-f", "IN-USE,SSID,SIGNAL,SECURITY", "device", "wifi", "list"]
        running: false
        stdout: StdioCollector {
            onStreamFinished: {
                let text = this.text;
                let scanList = [];
                let connected = [];

                let lines = text.split("\n");
                for (let line of lines) {
                    if (!line.trim())
                        continue;

                    let parts = line.split(":");
                    if (parts.length >= 3) {
                        let inUse = parts[0] === "*";
                        let name = parts[1] || "Unknown";
                        let signal = parts[2] || "0";
                        let security = parts[3] || "";

                        // 跳过空 SSID
                        if (!name || name === "")
                            continue;

                        let wifiItem = {
                            name: name,
                            signal: signal,
                            security: security
                        };

                        if (inUse) {
                            connected.push(wifiItem);
                        } else {
                            scanList.push(wifiItem);
                        }
                    }
                }

                configPanel.wifiConnected = connected;
                configPanel.wifiList = scanList;
            }
        }
    }

    Process {
        id: bluetoothConnectedProcess
        command: ["bluetoothctl", "devices", "Connected"]
        running: false
        stdout: StdioCollector {
            onStreamFinished: {
                try {
                    let text = this.text;
                    let connectedDevices = [];
                    let lines = text.split("\n");

                    for (let line of lines) {
                        let parts = line.split(" ");
                        if (parts.length >= 3) {
                            let address = parts[1];
                            let name = parts.slice(2).join(" ");
                            connectedDevices.push({
                                address: address,
                                name: name
                            });
                        }
                    }

                    configPanel.connectedModel = connectedDevices;
                } catch (e) {
                    console.warn("Failed to parse connected data:", this.text);
                }
            }
        }
    }

    Process {
        id: wallPapersList
        command: ["python3", Config.shellDir + "/scripts/wallPaper.py"]
        running: false
        stdout: StdioCollector {
            onStreamFinished: {
                try {
                    let datas = JSON.parse(this.text);
                    configPanel.wallPaperModel = datas;
                } catch (e) {
                    console.warn("Failed to parse wallpaper data:", this.text);
                }
            }
        }
    }

    Process {
        id: bluetoothList
        command: ["bluetoothctl", "--timeout", "10", "scan", "on"]
        running: false
        stdout: StdioCollector {
            onStreamFinished: {
                try {
                    let text = this.text;
                    // 移除 ANSI 颜色码
                    text = text.replace(/\x1b\[[0-9;]*m/g, "");
                    let lines = text.split("\n");
                    let devices = [];

                    for (let line of lines) {
                        line = line.trim();
                        if (line.startsWith("[NEW] Device")) {
                            let parts = line.split(" ");
                            if (parts.length >= 4) {
                                let address = parts[2];
                                let name = parts.slice(3).join(" ");
                                if (name.replace(/-/g, ":") === address) {
                                    name = "Unknown";
                                }
                                devices.push({
                                    address: address,
                                    name: name
                                });
                            }
                        }
                    }

                    configPanel.bluetoothModel = devices;
                } catch (e) {
                    console.warn("Failed to parse bluetooth data:", e);
                }
            }
        }
    }

    Process {
        id: niriOutput
        command: ["niri", "msg", "outputs"]
        running: true
        stdout: StdioCollector {
            onStreamFinished: {
                try {
                    let outputs = this.text;
                    let lines = outputs.split("\n");
                    let monitors = [];
                    let monitorInfo = null;
                    let inBlock = false;

                    for (let line of lines) {
                        let trim = line.trim();
                        if (trim.startsWith("Output")) {
                            if (monitorInfo && monitorInfo.name) {
                                monitors.push(monitorInfo);
                            }

                            monitorInfo = {
                                name: "",
                                modes: [],
                                currentMode: "",
                                scale: "1"
                            };
                            let monitorMatch = trim.match(/Output\s+"[^"]*"\s+\(([^)]+)\)/);
                            if (monitorMatch) {
                                monitorInfo.name = monitorMatch[1];
                            }
                            inBlock = false;
                        } else if (trim.startsWith("Scale:")) {
                            // 解析 Scale: 1
                            let scaleMatch = trim.match(/Scale:\s*([\d.]+)/);
                            if (scaleMatch && monitorInfo) {
                                monitorInfo.scale = scaleMatch[1];
                            }
                        } else if (trim.startsWith("Available modes:")) {
                            inBlock = true;
                        } else if (inBlock) {
                            let modeMatch = trim.match(/(\d+x\d+@\d+\.\d+)/);
                            if (modeMatch && trim.includes("current")) {
                                monitorInfo.currentMode = modeMatch[1];
                            } else if (modeMatch) {
                                monitorInfo.modes.push(modeMatch[1]);
                            }
                        } else if (trim === "") {
                            inBlock = false;
                        }
                    }

                    if (monitorInfo && monitorInfo.name) {
                        monitors.push(monitorInfo);
                    }

                    configPanel.monitors = monitors;
                } catch (e) {
                    console.warn("Failed to parse niri output:", e);
                }
            }
        }
    }

    Timer {
        interval: 11000
        running: configPanel.currentPanel === 2
        repeat: true
        onTriggered: {
            bluetoothList.running = true;
        }
    }

    Timer {
        interval: 5000
        running: configPanel.currentPanel === 3
        repeat: true
        onTriggered: {
            wifiList.running = true;
        }
    }

    Timer {
        id: refreshConnectedTimer
        interval: 500
        repeat: false
        onTriggered: {
            bluetoothConnectedProcess.running = true;
        }
    }

    Timer {
        id: refreshBluetoothTimer
        interval: 5000
        repeat: false
        onTriggered: {
            bluetoothConnectedProcess.running = true;
            bluetoothList.running = true;
        }
    }

    Timer {
        id: refreshWifiTimer
        interval: 3000
        repeat: false
        onTriggered: {
            wifiList.running = true;
        }
    }

    Component.onCompleted: {
        wallPapersList.running = true;
        bluetoothConnectedProcess.running = true;
        wifiList.running = true;
    }

    Item {
        id: configContainer
        //anchors.fill: parent
        anchors.centerIn: parent
        width: Config.sc(900)
        height: Config.sc(650)

        RowLayout {
            anchors.fill: parent
            spacing: 0

            // Left Sidebar
            Rectangle {
                Layout.preferredWidth: Config.sc(220)
                Layout.fillHeight: true
                color: Config.foreground
                topLeftRadius: Config.sc(35)
                bottomLeftRadius: Config.sc(35)

                ColumnLayout {
                    anchors.fill: parent
                    anchors.margins: Config.sc(Config.gaps)
                    spacing: Config.sc(20)

                    Text {
                        text: "Settings"
                        color: Config.text
                        font.pixelSize: Config.scFont(20)
                        font.bold: true
                        font.family: Config.fontFamily
                        Layout.topMargin: Config.sc(2)
                        Layout.leftMargin: Config.sc(20)
                    }

                    SidebarItem {
                        icon: ""
                        label: "Appearance"
                        isActive: configPanel.currentPanel === 0
                        onClicked: configPanel.currentPanel = 0
                    }

                    SidebarItem {
                        icon: ""
                        label: "Wallpaper"
                        isActive: configPanel.currentPanel === 1
                        onClicked: configPanel.currentPanel = 1
                    }

                    SidebarItem {
                        icon: ""
                        label: "Bluetooth"
                        isActive: configPanel.currentPanel === 2
                        onClicked: configPanel.currentPanel = 2
                    }

                    SidebarItem {
                        icon: ""
                        label: "WiFi"
                        isActive: configPanel.currentPanel === 3
                        onClicked: configPanel.currentPanel = 3
                    }

                    SidebarItem {
                        icon: "\uf108"
                        label: "Display"
                        isActive: configPanel.currentPanel === 4
                        onClicked: configPanel.currentPanel = 4
                    }

                    Item {
                        Layout.fillHeight: true
                    }
                }
            }

            // Content Area
            Item {
                Layout.fillWidth: true
                Layout.fillHeight: true

                Loader {
                    anchors.fill: parent
                    sourceComponent: {
                        if (configPanel.currentPanel === 0)
                            return appearancePanelComponent;
                        else if (configPanel.currentPanel === 1)
                            return wallpaperPanelComponent;
                        else if (configPanel.currentPanel === 2)
                            return blueToothPanelComponent;
                        else if (configPanel.currentPanel === 3)
                            return wifiPanelComponent;
                        else if (configPanel.currentPanel === 4)
                            return displayPanelComponent;
                        return null;
                    }

                    Component {
                        id: appearancePanelComponent
                        AppearancePanel {}
                    }

                    Component {
                        id: wallpaperPanelComponent
                        WallpaperPanel {}
                    }

                    Component {
                        id: blueToothPanelComponent
                        BlueToothPanel {}
                    }

                    Component {
                        id: wifiPanelComponent
                        WifiPanel {}
                    }

                    Component {
                        id: displayPanelComponent
                        DisplayPanel {}
                    }
                }
            }
        }
    }

    // Sidebar Item
    component SidebarItem: Rectangle {
        property string icon: ""
        property string label: ""
        property bool isActive: false
        signal clicked

        Layout.fillWidth: true
        Layout.preferredHeight: Config.sc(50)
        color: isActive ? Config.textHover : (hovered ? Config.textselect : "transparent")
        radius: Config.sc(8)

        property bool hovered: false

        RowLayout {
            anchors.fill: parent
            anchors.leftMargin: Config.sc(20)
            anchors.rightMargin: Config.sc(20)
            spacing: Config.sc(20)

            Text {
                text: icon
                color: Config.text
                font.pixelSize: Config.scFont(18)
                font.bold: true
                font.family: Config.fontFamily
            }

            Text {
                text: label
                color: Config.text
                font.pixelSize: Config.scFont(15)
                font.bold: true
                font.family: Config.fontFamily
                Layout.fillWidth: true
                Layout.topMargin: Config.sc(3)
            }
        }

        MouseArea {
            anchors.fill: parent
            hoverEnabled: true
            cursorShape: Qt.PointingHandCursor
            onEntered: parent.hovered = true
            onExited: parent.hovered = false
            onClicked: parent.clicked()
        }
    }

    // Toggle Switch
    component ToggleSwitch: Rectangle {
        id: toggleSwitch
        property bool checked: true
        property bool bindable: false  // When true, checked is controlled externally
        signal toggled

        width: Config.sc(44)
        height: Config.sc(24)
        color: checked ? Config.textHover : Config.progressColor
        radius: height / 2

        Rectangle {
            width: parent.height - Config.sc(6)
            height: width
            x: parent.checked ? parent.width - width - Config.sc(3) : Config.sc(3)
            y: (parent.height - height) / 2
            color: Config.text
            radius: width / 2

            Behavior on x {
                NumberAnimation {
                    duration: 150
                    easing.type: Easing.InOutQuad
                }
            }
        }

        MouseArea {
            anchors.fill: parent
            cursorShape: Qt.PointingHandCursor
            onClicked: {
                if (!toggleSwitch.bindable) {
                    toggleSwitch.checked = !toggleSwitch.checked;
                }
                toggleSwitch.toggled();
            }
        }
    }

    // Appearance Panel
    component AppearancePanel: Rectangle {
        color: Config.background
        topRightRadius: Config.sc(35)
        bottomRightRadius: Config.sc(35)

        ColumnLayout {
            anchors.fill: parent
            spacing: 0

            // Header
            RowLayout {
                Layout.fillWidth: true
                Layout.leftMargin: Config.sc(20)
                Layout.rightMargin: Config.sc(20)
                Layout.topMargin: Config.sc(20)
                spacing: Config.sc(20)

                Text {
                    text: "Appearance"
                    color: Config.text
                    font.pixelSize: Config.scFont(20)
                    font.bold: true
                    font.family: Config.fontFamily
                }

                Item {
                    Layout.fillWidth: true
                }

                Item {
                    Layout.preferredWidth: Config.sc(60)
                    Layout.preferredHeight: Config.sc(32)

                    property bool pressed: false
                    property bool hovered: false

                    Rectangle {
                        anchors.fill: parent
                        color: Config.textHover
                        radius: height / 2
                        scale: parent.pressed ? 0.9 : 1
                        opacity: parent.hovered ? 1 : 0.8

                        Behavior on scale {
                            NumberAnimation {
                                duration: 100
                                easing.type: Easing.InOutQuad
                            }
                        }

                        Behavior on opacity {
                            NumberAnimation {
                                duration: 200
                                easing.type: Easing.InOutQuad
                            }
                        }

                        Text {
                            anchors.centerIn: parent
                            text: "Apply"
                            color: Config.text
                            font.pixelSize: Config.scFont(15)
                            font.family: Config.fontFamily
                        }
                    }

                    MouseArea {
                        anchors.fill: parent
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
                        onPressed: parent.pressed = true
                        onReleased: parent.pressed = false
                        onEntered: parent.hovered = true
                        onExited: parent.hovered = false
                        onClicked: {
                            Buttoncommand.niriSettingExec(Config.niriInfo);
                        }
                    }
                }

                Item {
                    Layout.preferredWidth: Config.sc(32)
                    Layout.preferredHeight: Config.sc(32)

                    property bool isHovered: false

                    Rectangle {
                        anchors.fill: parent
                        color: Config.foreground
                        radius: height / 2
                        opacity: parent.isHovered ? 1 : 0

                        Behavior on opacity {
                            NumberAnimation {
                                duration: 200
                                easing.type: Easing.InOutQuad
                            }
                        }
                    }

                    Text {
                        anchors.centerIn: parent
                        text: "\uf00d"
                        color: Config.text
                        font.pixelSize: Config.scFont(15)
                        font.bold: true
                        font.family: Config.fontFamily
                    }

                    MouseArea {
                        anchors.fill: parent
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
                        onEntered: parent.isHovered = true
                        onExited: parent.isHovered = false
                        onClicked: Config.configPanelVisible = false
                    }
                }
            }

            // 可滚动内容
            Flickable {
                Layout.fillWidth: true
                Layout.fillHeight: true
                Layout.rightMargin: Config.sc(7)
                Layout.leftMargin: Config.sc(20)
                Layout.topMargin: Config.sc(20)
                clip: true
                boundsBehavior: Flickable.StopAtBounds
                contentWidth: width
                contentHeight: appearanceColumn.height

                ScrollBar.vertical: ScrollBar {
                    policy: ScrollBar.AsNeeded
                }

                ColumnLayout {
                    id: appearanceColumn
                    width: parent.width - Config.sc(17)
                    anchors.left: parent.left
                    spacing: Config.sc(20)

                    // Window Section
                    Item {
                        Layout.fillWidth: true
                        Layout.preferredHeight: Config.sc(32)

                        Text {
                            text: "Window"
                            color: Config.text
                            font.pixelSize: Config.scFont(15)
                            font.family: Config.fontFamily
                            font.bold: true
                            anchors.verticalCenter: parent.verticalCenter
                        }
                    }

                    Rectangle {
                        Layout.fillWidth: true
                        Layout.preferredHeight: windowColumn.height
                        color: Config.foreground
                        radius: Config.sc(15)

                        Column {
                            id: windowColumn
                            width: parent.width

                            // Gaps
                            Item {
                                width: parent.width
                                height: Config.sc(60)

                                RowLayout {
                                    anchors.fill: parent
                                    anchors.leftMargin: Config.sc(20)
                                    anchors.rightMargin: Config.sc(20)

                                    Text {
                                        text: "Gaps"
                                        color: Config.text
                                        font.pixelSize: Config.scFont(15)
                                        font.family: Config.fontFamily
                                    }

                                    Item {
                                        Layout.fillWidth: true
                                    }

                                    NumberField {
                                        value: Config.niriInfo ? Config.niriInfo["layout"]["gaps"] : "20"
                                        suffix: "px"
                                        onValueChanged: Config.niriInfo["layout"]["gaps"] = value
                                    }
                                }

                                Rectangle {
                                    anchors.bottom: parent.bottom
                                    width: parent.width
                                    height: 1
                                    color: Config.progressColor
                                    opacity: 1
                                }
                            }

                            // Corner Radius
                            Item {
                                width: parent.width
                                height: Config.sc(60)

                                RowLayout {
                                    anchors.fill: parent
                                    anchors.leftMargin: Config.sc(20)
                                    anchors.rightMargin: Config.sc(20)

                                    Text {
                                        text: "Corner Radius"
                                        color: Config.text
                                        font.pixelSize: Config.scFont(15)
                                        font.family: Config.fontFamily
                                    }

                                    Item {
                                        Layout.fillWidth: true
                                    }

                                    NumberField {
                                        value: Config.niriInfo && Config.niriInfo["corner_radius"] ? Config.niriInfo["corner_radius"]["radius"] : "15"
                                        suffix: "px"
                                        onValueChanged: Config.niriInfo["corner_radius"]["radius"] = value
                                    }
                                }
                            }
                        }
                    }

                    // Focus Ring Section
                    Item {
                        Layout.fillWidth: true
                        Layout.preferredHeight: Config.sc(32)

                        Text {
                            text: "Focus Ring"
                            color: Config.text
                            font.pixelSize: Config.scFont(15)
                            font.family: Config.fontFamily
                            font.bold: true
                            anchors.verticalCenter: parent.verticalCenter
                        }
                    }

                    Rectangle {
                        Layout.fillWidth: true
                        Layout.preferredHeight: focusRingColumn.height
                        color: Config.foreground
                        radius: Config.sc(15)

                        Column {
                            id: focusRingColumn
                            width: parent.width

                            // Enable
                            Item {
                                width: parent.width
                                height: Config.sc(60)

                                RowLayout {
                                    anchors.fill: parent
                                    anchors.leftMargin: Config.sc(20)
                                    anchors.rightMargin: Config.sc(20)

                                    Text {
                                        text: "Enable"
                                        color: Config.text
                                        font.pixelSize: Config.scFont(15)
                                        font.family: Config.fontFamily
                                    }

                                    Item {
                                        Layout.fillWidth: true
                                    }

                                    ToggleSwitch {
                                        id: focusRingEnableSwitch
                                        checked: Config.niriInfo ? Config.niriInfo["focus-ring"]["enable"] : true
                                        onToggled: Config.niriInfo["focus-ring"]["enable"] = checked
                                    }
                                }

                                Rectangle {
                                    anchors.bottom: parent.bottom
                                    width: parent.width
                                    height: 1
                                    color: Config.progressColor
                                    opacity: 1
                                }
                            }

                            // Width
                            Item {
                                width: parent.width
                                height: Config.sc(60)
                                opacity: focusRingEnableSwitch.checked ? 1 : 0.5

                                RowLayout {
                                    anchors.fill: parent
                                    anchors.leftMargin: Config.sc(20)
                                    anchors.rightMargin: Config.sc(20)

                                    Text {
                                        text: "Width"
                                        color: Config.text
                                        font.pixelSize: Config.scFont(15)
                                        font.family: Config.fontFamily
                                    }

                                    Item {
                                        Layout.fillWidth: true
                                    }

                                    NumberField {
                                        value: Config.niriInfo ? Config.niriInfo["focus-ring"]["width"] : "4"
                                        suffix: "px"
                                        enabled: focusRingEnableSwitch.checked
                                        onValueChanged: Config.niriInfo["focus-ring"]["width"] = value
                                    }
                                }

                                Rectangle {
                                    anchors.bottom: parent.bottom
                                    width: parent.width
                                    height: 1
                                    color: Config.progressColor
                                    opacity: 1
                                }
                            }

                            // Color
                            Item {
                                width: parent.width
                                height: Config.sc(60)
                                opacity: focusRingEnableSwitch.checked ? 1 : 0.5

                                RowLayout {
                                    anchors.fill: parent
                                    anchors.leftMargin: Config.sc(20)
                                    anchors.rightMargin: Config.sc(20)

                                    Text {
                                        text: "Color"
                                        color: Config.text
                                        font.pixelSize: Config.scFont(15)
                                        font.family: Config.fontFamily
                                    }

                                    Item {
                                        Layout.fillWidth: true
                                    }

                                    RowLayout {
                                        spacing: Config.sc(8)

                                        Rectangle {
                                            width: Config.sc(20)
                                            height: Config.sc(20)
                                            radius: height / 2
                                            color: focusRingColorInput.text
                                            border.width: 1
                                            border.color: Config.progressColor
                                        }

                                        Rectangle {
                                            width: Config.sc(90)
                                            height: Config.sc(32)
                                            color: Config.background
                                            border.color: Config.progressColor
                                            border.width: 1
                                            radius: Config.sc(6)

                                            TextField {
                                                id: focusRingColorInput
                                                anchors.fill: parent
                                                anchors.leftMargin: Config.sc(8)
                                                anchors.rightMargin: Config.sc(8)
                                                text: Config.niriInfo ? Config.niriInfo["focus-ring"]["color"] : "#7fc8ff"
                                                color: Config.text
                                                font.pixelSize: Config.scFont(15)
                                                font.family: Config.fontFamily
                                                background: Rectangle {
                                                    color: "transparent"
                                                }
                                                selectByMouse: true
                                                enabled: focusRingEnableSwitch.checked
                                                onTextChanged: Config.niriInfo["focus-ring"]["color"] = text
                                            }
                                        }
                                    }
                                }
                            }
                        }
                    }

                    // Border Section
                    Item {
                        Layout.fillWidth: true
                        Layout.preferredHeight: Config.sc(32)

                        Text {
                            text: "Border"
                            color: Config.text
                            font.pixelSize: Config.scFont(15)
                            font.family: Config.fontFamily
                            font.bold: true
                            anchors.verticalCenter: parent.verticalCenter
                        }
                    }

                    Rectangle {
                        Layout.fillWidth: true
                        Layout.preferredHeight: borderColumn.height
                        color: Config.foreground
                        radius: Config.sc(15)

                        Column {
                            id: borderColumn
                            width: parent.width

                            // Enable
                            Item {
                                width: parent.width
                                height: Config.sc(60)

                                RowLayout {
                                    anchors.fill: parent
                                    anchors.leftMargin: Config.sc(20)
                                    anchors.rightMargin: Config.sc(20)

                                    Text {
                                        text: "Enable"
                                        color: Config.text
                                        font.pixelSize: Config.scFont(15)
                                        font.family: Config.fontFamily
                                    }

                                    Item {
                                        Layout.fillWidth: true
                                    }

                                    ToggleSwitch {
                                        id: borderEnableSwitch
                                        checked: Config.niriInfo ? Config.niriInfo["border"]["enable"] : true
                                        onToggled: Config.niriInfo["border"]["enable"] = checked
                                    }
                                }

                                Rectangle {
                                    anchors.bottom: parent.bottom
                                    width: parent.width
                                    height: 1
                                    color: Config.progressColor
                                    opacity: 1
                                }
                            }

                            // Width
                            Item {
                                width: parent.width
                                height: Config.sc(60)
                                opacity: borderEnableSwitch.checked ? 1 : 0.5

                                RowLayout {
                                    anchors.fill: parent
                                    anchors.leftMargin: Config.sc(20)
                                    anchors.rightMargin: Config.sc(20)

                                    Text {
                                        text: "Width"
                                        color: Config.text
                                        font.pixelSize: Config.scFont(15)
                                        font.family: Config.fontFamily
                                    }

                                    Item {
                                        Layout.fillWidth: true
                                    }

                                    NumberField {
                                        value: Config.niriInfo ? Config.niriInfo["border"]["width"] : "4"
                                        suffix: "px"
                                        enabled: borderEnableSwitch.checked
                                        onValueChanged: Config.niriInfo["border"]["width"] = value
                                    }
                                }

                                Rectangle {
                                    anchors.bottom: parent.bottom
                                    width: parent.width
                                    height: 1
                                    color: Config.progressColor
                                    opacity: 1
                                }
                            }

                            // Color
                            Item {
                                width: parent.width
                                height: Config.sc(60)
                                opacity: borderEnableSwitch.checked ? 1 : 0.5

                                RowLayout {
                                    anchors.fill: parent
                                    anchors.leftMargin: Config.sc(20)
                                    anchors.rightMargin: Config.sc(20)

                                    Text {
                                        text: "Color"
                                        color: Config.text
                                        font.pixelSize: Config.scFont(15)
                                        font.family: Config.fontFamily
                                    }

                                    Item {
                                        Layout.fillWidth: true
                                    }

                                    RowLayout {
                                        spacing: Config.sc(8)

                                        Rectangle {
                                            width: Config.sc(20)
                                            height: Config.sc(20)
                                            radius: height / 2
                                            color: borderColorInput.text
                                            border.width: 1
                                            border.color: Config.progressColor
                                        }

                                        Rectangle {
                                            width: Config.sc(90)
                                            height: Config.sc(32)
                                            color: Config.background
                                            border.color: Config.progressColor
                                            border.width: 1
                                            radius: Config.sc(6)

                                            TextField {
                                                id: borderColorInput
                                                anchors.fill: parent
                                                anchors.leftMargin: Config.sc(8)
                                                anchors.rightMargin: Config.sc(8)
                                                text: Config.niriInfo ? Config.niriInfo["border"]["color"] : "#ffc87f"
                                                color: Config.text
                                                font.pixelSize: Config.scFont(15)
                                                font.family: Config.fontFamily
                                                background: Rectangle {
                                                    color: "transparent"
                                                }
                                                selectByMouse: true
                                                enabled: borderEnableSwitch.checked
                                                onTextChanged: Config.niriInfo["border"]["color"] = text
                                            }
                                        }
                                    }
                                }
                            }
                        }
                    }

                    // Shadow Section
                    Item {
                        Layout.fillWidth: true
                        Layout.preferredHeight: Config.sc(32)

                        Text {
                            text: "Shadow"
                            color: Config.text
                            font.pixelSize: Config.scFont(15)
                            font.family: Config.fontFamily
                            font.bold: true
                            anchors.verticalCenter: parent.verticalCenter
                        }
                    }

                    Rectangle {
                        Layout.fillWidth: true
                        Layout.preferredHeight: shadowColumn.height
                        color: Config.foreground
                        radius: Config.sc(15)

                        Column {
                            id: shadowColumn
                            width: parent.width

                            // Enable
                            Item {
                                width: parent.width
                                height: Config.sc(60)

                                RowLayout {
                                    anchors.fill: parent
                                    anchors.leftMargin: Config.sc(20)
                                    anchors.rightMargin: Config.sc(20)

                                    Text {
                                        text: "Enable"
                                        color: Config.text
                                        font.pixelSize: Config.scFont(15)
                                        font.family: Config.fontFamily
                                    }

                                    Item {
                                        Layout.fillWidth: true
                                    }

                                    ToggleSwitch {
                                        id: shadowEnableSwitch
                                        checked: Config.niriInfo ? Config.niriInfo["shadow"]["enable"] : false
                                        onToggled: Config.niriInfo["shadow"]["enable"] = checked
                                    }
                                }

                                Rectangle {
                                    anchors.bottom: parent.bottom
                                    width: parent.width
                                    height: 1
                                    color: Config.progressColor
                                    opacity: 1
                                }
                            }

                            // Softness
                            Item {
                                width: parent.width
                                height: Config.sc(60)
                                opacity: shadowEnableSwitch.checked ? 1 : 0.5

                                RowLayout {
                                    anchors.fill: parent
                                    anchors.leftMargin: Config.sc(20)
                                    anchors.rightMargin: Config.sc(20)

                                    Text {
                                        text: "Softness"
                                        color: Config.text
                                        font.pixelSize: Config.scFont(15)
                                        font.family: Config.fontFamily
                                    }

                                    Item {
                                        Layout.fillWidth: true
                                    }

                                    NumberField {
                                        value: Config.niriInfo ? Config.niriInfo["shadow"]["softness"] : "30"
                                        suffix: "px"
                                        enabled: shadowEnableSwitch.checked
                                        onValueChanged: Config.niriInfo["shadow"]["softness"] = value
                                    }
                                }

                                Rectangle {
                                    anchors.bottom: parent.bottom
                                    width: parent.width
                                    height: 1
                                    color: Config.progressColor
                                    opacity: 1
                                }
                            }

                            // Spread
                            Item {
                                width: parent.width
                                height: Config.sc(60)
                                opacity: shadowEnableSwitch.checked ? 1 : 0.5

                                RowLayout {
                                    anchors.fill: parent
                                    anchors.leftMargin: Config.sc(20)
                                    anchors.rightMargin: Config.sc(20)

                                    Text {
                                        text: "Spread"
                                        color: Config.text
                                        font.pixelSize: Config.scFont(15)
                                        font.family: Config.fontFamily
                                    }

                                    Item {
                                        Layout.fillWidth: true
                                    }

                                    NumberField {
                                        value: Config.niriInfo ? Config.niriInfo["shadow"]["spread"] : "5"
                                        suffix: "px"
                                        enabled: shadowEnableSwitch.checked
                                        onValueChanged: Config.niriInfo["shadow"]["spread"] = value
                                    }
                                }

                                Rectangle {
                                    anchors.bottom: parent.bottom
                                    width: parent.width
                                    height: 1
                                    color: Config.progressColor
                                    opacity: 1
                                }
                            }

                            // Offset
                            Item {
                                width: parent.width
                                height: Config.sc(60)
                                opacity: shadowEnableSwitch.checked ? 1 : 0.5

                                RowLayout {
                                    anchors.fill: parent
                                    anchors.leftMargin: Config.sc(20)
                                    anchors.rightMargin: Config.sc(20)

                                    Text {
                                        text: "Offset"
                                        color: Config.text
                                        font.pixelSize: Config.scFont(15)
                                        font.family: Config.fontFamily
                                    }

                                    Item {
                                        Layout.fillWidth: true
                                    }

                                    RowLayout {
                                        spacing: Config.sc(8)

                                        NumberField {
                                            value: Config.niriInfo && Config.niriInfo["shadow"]["offset"] ? Config.niriInfo["shadow"]["offset"]["x"] : "0"
                                            suffix: "X"
                                            enabled: shadowEnableSwitch.checked
                                            onValueChanged: Config.niriInfo["shadow"]["offset"]["x"] = value
                                        }

                                        NumberField {
                                            value: Config.niriInfo && Config.niriInfo["shadow"]["offset"] ? Config.niriInfo["shadow"]["offset"]["y"] : "5"
                                            suffix: "Y"
                                            enabled: shadowEnableSwitch.checked
                                            onValueChanged: Config.niriInfo["shadow"]["offset"]["y"] = value
                                        }
                                    }
                                }

                                Rectangle {
                                    anchors.bottom: parent.bottom
                                    width: parent.width
                                    height: 1
                                    color: Config.progressColor
                                    opacity: 1
                                }
                            }

                            // Color
                            Item {
                                width: parent.width
                                height: Config.sc(60)
                                opacity: shadowEnableSwitch.checked ? 1 : 0.5

                                RowLayout {
                                    anchors.fill: parent
                                    anchors.leftMargin: Config.sc(20)
                                    anchors.rightMargin: Config.sc(20)

                                    Text {
                                        text: "Color"
                                        color: Config.text
                                        font.pixelSize: Config.scFont(15)
                                        font.family: Config.fontFamily
                                    }

                                    Item {
                                        Layout.fillWidth: true
                                    }

                                    RowLayout {
                                        spacing: Config.sc(8)

                                        Rectangle {
                                            width: Config.sc(20)
                                            height: Config.sc(20)
                                            radius: height / 2
                                            color: shadowColorInput.text
                                            border.width: 1
                                            border.color: Config.progressColor
                                        }

                                        Rectangle {
                                            width: Config.sc(90)
                                            height: Config.sc(32)
                                            color: Config.background
                                            border.color: Config.progressColor
                                            border.width: 1
                                            radius: Config.sc(6)

                                            TextField {
                                                id: shadowColorInput
                                                anchors.fill: parent
                                                anchors.leftMargin: Config.sc(8)
                                                anchors.rightMargin: Config.sc(8)
                                                text: Config.niriInfo ? Config.niriInfo["shadow"]["color"] : "#000000"
                                                color: Config.text
                                                font.pixelSize: Config.scFont(15)
                                                font.family: Config.fontFamily
                                                background: Rectangle {
                                                    color: "transparent"
                                                }
                                                selectByMouse: true
                                                enabled: shadowEnableSwitch.checked
                                                onTextChanged: Config.niriInfo["shadow"]["color"] = text
                                            }
                                        }
                                    }
                                }
                            }
                        }
                    }

                    // Animations Section
                    Item {
                        Layout.fillWidth: true
                        Layout.preferredHeight: Config.sc(32)

                        Text {
                            text: "Animations"
                            color: Config.text
                            font.pixelSize: Config.scFont(15)
                            font.family: Config.fontFamily
                            font.bold: true
                            anchors.verticalCenter: parent.verticalCenter
                        }
                    }

                    Rectangle {
                        Layout.fillWidth: true
                        Layout.preferredHeight: animationsColumn.height
                        color: Config.foreground
                        radius: Config.sc(15)

                        Column {
                            id: animationsColumn
                            width: parent.width

                            // Enable
                            Item {
                                width: parent.width
                                height: Config.sc(60)

                                RowLayout {
                                    anchors.fill: parent
                                    anchors.leftMargin: Config.sc(20)
                                    anchors.rightMargin: Config.sc(20)

                                    Text {
                                        text: "Enable"
                                        color: Config.text
                                        font.pixelSize: Config.scFont(15)
                                        font.family: Config.fontFamily
                                    }

                                    Item {
                                        Layout.fillWidth: true
                                    }

                                    ToggleSwitch {
                                        id: animationsEnableSwitch
                                        checked: Config.niriInfo ? Config.niriInfo["animations"]["enable"] : true
                                        onToggled: Config.niriInfo["animations"]["enable"] = checked
                                    }
                                }

                                Rectangle {
                                    anchors.bottom: parent.bottom
                                    width: parent.width
                                    height: 1
                                    color: Config.progressColor
                                    opacity: 1
                                }
                            }

                            // Slowdown
                            Item {
                                width: parent.width
                                height: Config.sc(60)
                                opacity: animationsEnableSwitch.checked ? 1 : 0.5

                                RowLayout {
                                    anchors.fill: parent
                                    anchors.leftMargin: Config.sc(20)
                                    anchors.rightMargin: Config.sc(20)

                                    Text {
                                        text: "Slowdown"
                                        color: Config.text
                                        font.pixelSize: Config.scFont(15)
                                        font.family: Config.fontFamily
                                    }

                                    Item {
                                        Layout.fillWidth: true
                                    }

                                    NumberField {
                                        value: Config.niriInfo && Config.niriInfo["animations"] ? Config.niriInfo["animations"]["slowdown"] : "1.0"
                                        suffix: "x"
                                        enabled: animationsEnableSwitch.checked
                                        onValueChanged: Config.niriInfo["animations"]["slowdown"] = value
                                    }
                                }
                            }
                        }
                    }

                    // Extra Gaps Section
                    Item {
                        Layout.fillWidth: true
                        Layout.preferredHeight: Config.sc(32)

                        Text {
                            text: "Extra Gaps"
                            color: Config.text
                            font.pixelSize: Config.scFont(15)
                            font.family: Config.fontFamily
                            font.bold: true
                            anchors.verticalCenter: parent.verticalCenter
                        }
                    }

                    Rectangle {
                        Layout.fillWidth: true
                        Layout.preferredHeight: extraGapsColumn.height
                        color: Config.foreground
                        radius: Config.sc(15)

                        Column {
                            id: extraGapsColumn
                            width: parent.width

                            // Enable
                            Item {
                                width: parent.width
                                height: Config.sc(60)

                                RowLayout {
                                    anchors.fill: parent
                                    anchors.leftMargin: Config.sc(20)
                                    anchors.rightMargin: Config.sc(20)

                                    Text {
                                        text: "Enable"
                                        color: Config.text
                                        font.pixelSize: Config.scFont(15)
                                        font.family: Config.fontFamily
                                    }

                                    Item {
                                        Layout.fillWidth: true
                                    }

                                    ToggleSwitch {
                                        id: extraGapsEnableSwitch
                                        checked: Config.niriInfo ? Config.niriInfo["struts"]["enabled"] : false
                                        onToggled: Config.niriInfo["struts"]["enabled"] = checked
                                    }
                                }

                                Rectangle {
                                    anchors.bottom: parent.bottom
                                    width: parent.width
                                    height: 1
                                    color: Config.progressColor
                                    opacity: 1
                                }
                            }

                            // Top
                            Item {
                                width: parent.width
                                height: Config.sc(60)
                                opacity: extraGapsEnableSwitch.checked ? 1 : 0.5

                                RowLayout {
                                    anchors.fill: parent
                                    anchors.leftMargin: Config.sc(20)
                                    anchors.rightMargin: Config.sc(20)

                                    Text {
                                        text: "Top"
                                        color: Config.text
                                        font.pixelSize: Config.scFont(15)
                                        font.family: Config.fontFamily
                                    }

                                    Item {
                                        Layout.fillWidth: true
                                    }

                                    NumberField {
                                        value: Config.niriInfo && Config.niriInfo["struts"] ? Config.niriInfo["struts"]["top"] : "0"
                                        suffix: "px"
                                        enabled: extraGapsEnableSwitch.checked
                                        onValueChanged: Config.niriInfo["struts"]["top"] = value
                                    }
                                }

                                Rectangle {
                                    anchors.bottom: parent.bottom
                                    width: parent.width
                                    height: 1
                                    color: Config.progressColor
                                    opacity: 1
                                }
                            }

                            // Bottom
                            Item {
                                width: parent.width
                                height: Config.sc(60)
                                opacity: extraGapsEnableSwitch.checked ? 1 : 0.5

                                RowLayout {
                                    anchors.fill: parent
                                    anchors.leftMargin: Config.sc(20)
                                    anchors.rightMargin: Config.sc(20)

                                    Text {
                                        text: "Bottom"
                                        color: Config.text
                                        font.pixelSize: Config.scFont(15)
                                        font.family: Config.fontFamily
                                    }

                                    Item {
                                        Layout.fillWidth: true
                                    }

                                    NumberField {
                                        value: Config.niriInfo && Config.niriInfo["struts"] ? Config.niriInfo["struts"]["bottom"] : "0"
                                        suffix: "px"
                                        enabled: extraGapsEnableSwitch.checked
                                        onValueChanged: Config.niriInfo["struts"]["bottom"] = value
                                    }
                                }

                                Rectangle {
                                    anchors.bottom: parent.bottom
                                    width: parent.width
                                    height: 1
                                    color: Config.progressColor
                                    opacity: 1
                                }
                            }

                            // Left
                            Item {
                                width: parent.width
                                height: Config.sc(60)
                                opacity: extraGapsEnableSwitch.checked ? 1 : 0.5

                                RowLayout {
                                    anchors.fill: parent
                                    anchors.leftMargin: Config.sc(20)
                                    anchors.rightMargin: Config.sc(20)

                                    Text {
                                        text: "Left"
                                        color: Config.text
                                        font.pixelSize: Config.scFont(15)
                                        font.family: Config.fontFamily
                                    }

                                    Item {
                                        Layout.fillWidth: true
                                    }

                                    NumberField {
                                        value: Config.niriInfo && Config.niriInfo["struts"] ? Config.niriInfo["struts"]["left"] : "0"
                                        suffix: "px"
                                        enabled: extraGapsEnableSwitch.checked
                                        onValueChanged: Config.niriInfo["struts"]["left"] = value
                                    }
                                }

                                Rectangle {
                                    anchors.bottom: parent.bottom
                                    width: parent.width
                                    height: 1
                                    color: Config.progressColor
                                    opacity: 1
                                }
                            }

                            // Right
                            Item {
                                width: parent.width
                                height: Config.sc(60)
                                opacity: extraGapsEnableSwitch.checked ? 1 : 0.5

                                RowLayout {
                                    anchors.fill: parent
                                    anchors.leftMargin: Config.sc(20)
                                    anchors.rightMargin: Config.sc(20)

                                    Text {
                                        text: "Right"
                                        color: Config.text
                                        font.pixelSize: Config.scFont(15)
                                        font.family: Config.fontFamily
                                    }

                                    Item {
                                        Layout.fillWidth: true
                                    }

                                    NumberField {
                                        value: Config.niriInfo && Config.niriInfo["struts"] ? Config.niriInfo["struts"]["right"] : "0"
                                        suffix: "px"
                                        enabled: extraGapsEnableSwitch.checked
                                        onValueChanged: Config.niriInfo["struts"]["right"] = value
                                    }
                                }
                            }
                        }
                    }

                    Item {
                        Layout.fillHeight: true
                    }
                }
            }
        }
    }

    // Wallpaper Panel
    component WallpaperPanel: Rectangle {
        color: Config.background
        topRightRadius: Config.sc(35)
        bottomRightRadius: Config.sc(35)

        ColumnLayout {
            anchors.fill: parent
            spacing: 0

            // Header (固定，不滚动)
            RowLayout {
                Layout.fillWidth: true
                Layout.leftMargin: Config.sc(20)
                Layout.rightMargin: Config.sc(20)
                Layout.topMargin: Config.sc(20)
                spacing: Config.sc(20)

                Text {
                    text: "Wallpaper"
                    color: Config.text
                    font.pixelSize: Config.scFont(18)
                    font.bold: true
                    font.family: Config.fontFamily
                    //Layout.preferredWidth: Config.sc(120)
                    //Layout.alignment: Qt.AlignVCenter
                }

                Item {
                    Layout.fillWidth: true
                }

                Item {
                    Layout.preferredWidth: Config.sc(60)
                    Layout.preferredHeight: Config.sc(32)

                    property bool pressed: false
                    property bool hovered: false

                    Rectangle {
                        anchors.fill: parent
                        color: Config.textHover
                        radius: height / 2
                        scale: parent.pressed ? 0.9 : 1
                        opacity: parent.hovered ? 1 : 0.8

                        Behavior on scale {
                            NumberAnimation {
                                duration: 100
                                easing.type: Easing.InOutQuad
                            }
                        }

                        Behavior on opacity {
                            NumberAnimation {
                                duration: 200
                                easing.type: Easing.InOutQuad
                            }
                        }

                        Text {
                            anchors.centerIn: parent
                            text: "Apply"
                            color: Config.text
                            font.pixelSize: Config.scFont(15)
                            font.family: Config.fontFamily
                        }
                    }

                    MouseArea {
                        anchors.fill: parent
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
                        onPressed: parent.pressed = true
                        onReleased: parent.pressed = false
                        onEntered: parent.hovered = true
                        onExited: parent.hovered = false
                        onClicked: {
                            Buttoncommand.changeWallpaper(modelData.path);
                        }
                    }
                }

                Item {
                    Layout.preferredWidth: Config.sc(32)
                    Layout.preferredHeight: Config.sc(32)

                    property bool isHovered: false

                    Rectangle {
                        anchors.fill: parent
                        color: Config.foreground
                        radius: height / 2
                        opacity: parent.isHovered ? 1 : 0

                        Behavior on opacity {
                            NumberAnimation {
                                duration: 200
                                easing.type: Easing.InOutQuad
                            }
                        }
                    }

                    Text {
                        anchors.centerIn: parent
                        text: "\uf00d"
                        color: Config.text
                        font.pixelSize: Config.scFont(15)
                        font.bold: true
                        font.family: Config.fontFamily
                    }

                    MouseArea {
                        anchors.fill: parent
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
                        onEntered: parent.isHovered = true
                        onExited: parent.isHovered = false
                        onClicked: Config.configPanelVisible = false
                    }
                }
            }

            // 可滚动内容
            Flickable {
                id: wallpaperFlickable
                Layout.fillWidth: true
                Layout.fillHeight: true
                Layout.topMargin: Config.sc(16)
                Layout.leftMargin: Config.sc(20)
                Layout.rightMargin: Config.sc(12)
                Layout.bottomMargin: Config.sc(20)
                contentWidth: width
                contentHeight: wallpaperColumn.height
                clip: true
                boundsBehavior: Flickable.StopAtBounds

                ScrollBar.vertical: ScrollBar {
                    policy: ScrollBar.AsNeeded
                }

                ColumnLayout {
                    id: wallpaperColumn
                    width: parent.width
                    Layout.rightMargin: Config.sc(12)
                    spacing: Config.sc(16)

                    Text {
                        visible: configPanel.wallPaperModel.length === 0
                        text: "No wallpapers found"
                        color: Config.text
                        font.pixelSize: Config.scFont(15)
                        font.bold: true
                        font.family: Config.fontFamily
                        Layout.alignment: Qt.AlignHCenter
                    }

                    Flow {
                        Layout.fillWidth: true
                        spacing: Config.sc(12)

                        Repeater {
                            model: configPanel.wallPaperModel

                            Rectangle {
                                width: (wallpaperFlickable.width - Config.sc(36)) / 3
                                height: Math.round(((wallpaperFlickable.width - Config.sc(36)) / 3) * 9 / 16)
                                color: Config.foreground
                                radius: Config.sc(12)
                                border.width: index === configPanel.selectedWallpaperIndex ? 2 : 0
                                border.color: Config.textHover

                                Image {
                                    id: wallpaperImg
                                    anchors.fill: parent
                                    anchors.margins: Config.sc(6)
                                    source: modelData.path ? "file://" + modelData.path : ""
                                    fillMode: Image.PreserveAspectCrop
                                    asynchronous: true
                                    layer.enabled: true
                                    layer.effect: OpacityMask {
                                        maskSource: Rectangle {
                                            width: wallpaperImg.width
                                            height: wallpaperImg.height
                                            radius: Config.sc(8)
                                        }
                                    }
                                }

                                MouseArea {
                                    anchors.fill: parent
                                    cursorShape: Qt.PointingHandCursor
                                    onClicked: configPanel.selectedWallpaperIndex = index
                                }

                                Rectangle {
                                    visible: index === configPanel.selectedWallpaperIndex
                                    anchors.right: parent.right
                                    anchors.top: parent.top
                                    anchors.margins: Config.sc(8)
                                    width: Config.sc(22)
                                    height: Config.sc(22)
                                    color: Config.textHover
                                    radius: height / 2

                                    Text {
                                        anchors.centerIn: parent
                                        text: "\uf00c"
                                        color: Config.text
                                        font.pixelSize: Config.scFont(15)
                                        font.bold: true
                                        font.family: Config.fontFamily
                                    }
                                }
                            }
                        }
                    }
                }
            }
        }
    }

    // Number Field
    component NumberField: Rectangle {
        property string value: ""
        property string suffix: ""

        width: Config.sc(90)
        height: Config.sc(32)
        color: Config.background
        border.color: Config.progressColor
        border.width: 1
        radius: Config.sc(6)

        RowLayout {
            anchors.fill: parent
            anchors.leftMargin: Config.sc(8)
            anchors.rightMargin: Config.sc(8)

            TextField {
                Layout.fillWidth: true
                text: value
                color: Config.text
                font.pixelSize: Config.scFont(15)
                font.family: Config.fontFamily
                background: Rectangle {
                    color: "transparent"
                }
                selectByMouse: true
                onTextChanged: parent.parent.value = text
            }

            Text {
                text: suffix
                color: Config.text
                font.pixelSize: Config.scFont(15)
                font.family: Config.fontFamily
                visible: suffix !== ""
            }
        }
    }

    // Bluetooth Panel
    component BlueToothPanel: Rectangle {
        id: bluetoothPanel
        color: Config.background
        topRightRadius: Config.sc(35)
        bottomRightRadius: Config.sc(35)

        property bool bluetoothEnabled: true

        ColumnLayout {
            anchors.fill: parent
            spacing: 0

            // Header
            RowLayout {
                Layout.fillWidth: true
                Layout.leftMargin: Config.sc(20)
                Layout.rightMargin: Config.sc(20)
                Layout.topMargin: Config.sc(20)
                spacing: Config.sc(20)

                Text {
                    text: "Bluetooth"
                    color: Config.text
                    font.pixelSize: Config.scFont(20)
                    font.bold: true
                    font.family: Config.fontFamily
                }

                Item {
                    Layout.fillWidth: true
                }

                Item {
                    Layout.preferredWidth: Config.sc(32)
                    Layout.preferredHeight: Config.sc(32)

                    property bool isHovered: false

                    Rectangle {
                        anchors.fill: parent
                        color: Config.foreground
                        radius: height / 2
                        opacity: parent.isHovered ? 1 : 0

                        Behavior on opacity {
                            NumberAnimation {
                                duration: 200
                                easing.type: Easing.InOutQuad
                            }
                        }
                    }

                    Text {
                        anchors.centerIn: parent
                        text: "\uf00d"
                        color: Config.text
                        font.pixelSize: Config.scFont(15)
                        font.bold: true
                        font.family: Config.fontFamily
                    }

                    MouseArea {
                        anchors.fill: parent
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
                        onEntered: parent.isHovered = true
                        onExited: parent.isHovered = false
                        onClicked: Config.configPanelVisible = false
                    }
                }
            }

            Flickable {
                Layout.fillWidth: true
                Layout.fillHeight: true
                Layout.rightMargin: Config.sc(7)
                Layout.leftMargin: Config.sc(20)
                Layout.topMargin: Config.sc(20)
                clip: true
                boundsBehavior: Flickable.StopAtBounds
                contentWidth: width
                contentHeight: bluetoothColumn.height

                ScrollBar.vertical: ScrollBar {
                    policy: ScrollBar.AsNeeded
                }

                ColumnLayout {
                    id: bluetoothColumn
                    width: parent.width - Config.sc(17)
                    anchors.left: parent.left
                    spacing: Config.sc(20)

                    Rectangle {
                        Layout.fillWidth: true
                        Layout.preferredHeight: Config.sc(60)
                        color: Config.foreground
                        radius: 15

                        Text {
                            anchors.left: parent.left
                            anchors.leftMargin: Config.sc(20)
                            anchors.verticalCenter: parent.verticalCenter
                            text: "Bluetooth"
                            color: Config.text
                            font.pixelSize: Config.scFont(15)
                            font.family: Config.fontFamily
                        }

                        ToggleSwitch {
                            id: bluetoothToggle
                            anchors.right: parent.right
                            anchors.rightMargin: Config.sc(20)
                            anchors.verticalCenter: parent.verticalCenter
                            checked: bluetoothPanel.bluetoothEnabled
                            onToggled: {
                                bluetoothPanel.bluetoothEnabled = !bluetoothPanel.bluetoothEnabled;
                            }
                        }
                    }

                    Item {
                        Layout.fillWidth: true
                        Layout.preferredHeight: Config.sc(32)
                        visible: bluetoothPanel.bluetoothEnabled

                        Text {
                            id: newDevicesText
                            text: "New Devices"
                            color: Config.text
                            font.pixelSize: Config.scFont(15)
                            font.family: Config.fontFamily
                            font.bold: true
                            anchors.verticalCenter: parent.verticalCenter
                        }

                        Item {
                            id: loadingIcon
                            width: Config.sc(32)
                            height: Config.sc(32)
                            anchors.right: parent.right
                            anchors.verticalCenter: parent.verticalCenter

                            Text {
                                text: ""
                                font.pixelSize: Config.scFont(15)
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
                                running: configPanel.currentPanel === 2
                            }
                        }
                    }

                    Rectangle {
                        Layout.fillWidth: true
                        Layout.preferredHeight: Math.max(bluetoothList.count * Config.sc(60), Config.sc(60))
                        color: Config.foreground
                        radius: Config.sc(15)
                        visible: bluetoothPanel.bluetoothEnabled

                        Behavior on Layout.preferredHeight {
                            NumberAnimation {
                                duration: 150
                            }
                        }

                        Text {
                            text: "Searching for devices..."
                            font.pixelSize: Config.scFont(15)
                            font.family: Config.fontFamily
                            color: Config.text
                            anchors.centerIn: parent
                            visible: bluetoothList.count === 0
                        }

                        ListView {
                            id: bluetoothList
                            model: configPanel.bluetoothModel
                            anchors.fill: parent
                            spacing: Config.sc(0)
                            visible: bluetoothList.count > 0

                            delegate: Item {
                                id: bluetoothDelegate
                                width: parent.width
                                height: Config.sc(60)

                                property bool hovered: false

                                RowLayout {
                                    anchors.fill: parent
                                    spacing: Config.sc(0)

                                    Text {
                                        text: modelData.name
                                        font.pixelSize: Config.scFont(15)
                                        font.family: Config.fontFamily
                                        color: Config.text
                                        Layout.leftMargin: Config.sc(20)
                                    }

                                    Item {
                                        Layout.fillWidth: true
                                    }

                                    Item {
                                        width: Config.sc(90)
                                        height: Config.sc(40)
                                        Layout.rightMargin: Config.sc(20)

                                        property bool pressed: false

                                        Text {
                                            text: "Connect"
                                            font.pixelSize: Config.scFont(15)
                                            font.family: Config.fontFamily
                                            color: Config.text
                                            anchors.centerIn: parent
                                            z: 1
                                        }

                                        MouseArea {
                                            anchors.fill: parent
                                            hoverEnabled: true
                                            cursorShape: Qt.PointingHandCursor
                                            onEntered: bluetoothDelegate.hovered = true
                                            onExited: bluetoothDelegate.hovered = false
                                            onPressed: parent.pressed = true
                                            onReleased: parent.pressed = false
                                            onClicked: {
                                                Buttoncommand.bluetoothConnect(modelData.address);
                                                refreshBluetoothTimer.start();
                                            }
                                        }

                                        Rectangle {
                                            anchors.fill: parent
                                            color: Config.textHover
                                            radius: Config.sc(15)
                                            opacity: bluetoothDelegate.hovered ? 1 : 0.8
                                            scale: parent.pressed ? 0.9 : 1

                                            Behavior on opacity {
                                                NumberAnimation {
                                                    duration: 200
                                                    easing.type: Easing.InOutQuad
                                                }
                                            }

                                            Behavior on scale {
                                                NumberAnimation {
                                                    duration: 100
                                                    easing.type: Easing.InOutQuad
                                                }
                                            }
                                        }
                                    }
                                }

                                Rectangle {
                                    visible: index < bluetoothList.count - 1
                                    anchors.bottom: parent.bottom
                                    width: parent.width
                                    height: 1
                                    color: Config.progressColor
                                }
                            }
                        }
                    }

                    Item {
                        Layout.fillWidth: true
                        Layout.preferredHeight: Config.sc(32)
                        visible: bluetoothPanel.bluetoothEnabled

                        Text {
                            id: connectedDevices
                            text: "Connected Devices"
                            color: Config.text
                            font.pixelSize: Config.scFont(15)
                            font.family: Config.fontFamily
                            font.bold: true
                            anchors.verticalCenter: parent.verticalCenter
                        }
                    }

                    Rectangle {
                        Layout.fillWidth: true
                        Layout.preferredHeight: connectedList.count * Config.sc(60)
                        color: Config.foreground
                        radius: Config.sc(15)
                        visible: bluetoothPanel.bluetoothEnabled

                        Behavior on Layout.preferredHeight {
                            NumberAnimation {
                                duration: 200
                                easing.type: Easing.InOutQuad
                            }
                        }

                        ListView {
                            id: connectedList
                            model: configPanel.connectedModel
                            anchors.fill: parent
                            spacing: Config.sc(0)

                            delegate: Item {
                                id: delegateItem
                                width: parent.width
                                height: Config.sc(60)

                                property bool hovered: false

                                RowLayout {
                                    anchors.fill: parent
                                    spacing: Config.sc(0)

                                    Text {
                                        text: modelData.name
                                        font.pixelSize: Config.scFont(15)
                                        font.family: Config.fontFamily
                                        color: Config.text
                                        Layout.leftMargin: Config.sc(20)
                                    }

                                    Item {
                                        Layout.fillWidth: true
                                    }

                                    Item {
                                        width: Config.sc(90)
                                        height: Config.sc(40)
                                        Layout.rightMargin: Config.sc(20)

                                        property bool pressed: false

                                        Text {
                                            text: "Delete"
                                            font.pixelSize: Config.scFont(15)
                                            font.family: Config.fontFamily
                                            color: Config.text
                                            anchors.centerIn: parent
                                            z: 1
                                        }

                                        MouseArea {
                                            anchors.fill: parent
                                            hoverEnabled: true
                                            cursorShape: Qt.PointingHandCursor
                                            onEntered: delegateItem.hovered = true
                                            onExited: delegateItem.hovered = false
                                            onPressed: parent.pressed = true
                                            onReleased: parent.pressed = false
                                            onClicked: {
                                                Buttoncommand.bluetoothDisconnect(modelData.address);
                                                refreshConnectedTimer.start();
                                            }
                                        }

                                        Rectangle {
                                            anchors.fill: parent
                                            color: Config.closeColor
                                            radius: Config.sc(15)
                                            opacity: delegateItem.hovered ? 1 : 0.6
                                            scale: parent.pressed ? 0.9 : 1

                                            Behavior on opacity {
                                                NumberAnimation {
                                                    duration: 200
                                                    easing.type: Easing.InOutQuad
                                                }
                                            }

                                            Behavior on scale {
                                                NumberAnimation {
                                                    duration: 100
                                                    easing.type: Easing.InOutQuad
                                                }
                                            }
                                        }
                                    }
                                }

                                Rectangle {
                                    visible: index < connectedList.count - 1
                                    anchors.bottom: parent.bottom
                                    width: parent.width
                                    height: 1
                                    color: Config.progressColor
                                }
                            }
                        }
                    }
                }
            }
        }
    }

    // WiFi Panel
    component WifiPanel: Rectangle {
        id: wifiPanel
        color: Config.background
        topRightRadius: Config.sc(35)
        bottomRightRadius: Config.sc(35)

        property bool wifiEnabled: true

        ColumnLayout {
            anchors.fill: parent
            spacing: 0

            // Header
            RowLayout {
                Layout.fillWidth: true
                Layout.leftMargin: Config.sc(20)
                Layout.rightMargin: Config.sc(20)
                Layout.topMargin: Config.sc(20)
                spacing: Config.sc(20)

                Text {
                    text: "WiFi"
                    color: Config.text
                    font.pixelSize: Config.scFont(20)
                    font.bold: true
                    font.family: Config.fontFamily
                }

                Item {
                    Layout.fillWidth: true
                }

                Item {
                    Layout.preferredWidth: Config.sc(32)
                    Layout.preferredHeight: Config.sc(32)

                    property bool isHovered: false

                    Rectangle {
                        anchors.fill: parent
                        color: Config.foreground
                        radius: height / 2
                        opacity: parent.isHovered ? 1 : 0

                        Behavior on opacity {
                            NumberAnimation {
                                duration: 200
                                easing.type: Easing.InOutQuad
                            }
                        }
                    }

                    Text {
                        anchors.centerIn: parent
                        text: "\uf00d"
                        color: Config.text
                        font.pixelSize: Config.scFont(15)
                        font.bold: true
                        font.family: Config.fontFamily
                    }

                    MouseArea {
                        anchors.fill: parent
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
                        onEntered: parent.isHovered = true
                        onExited: parent.isHovered = false
                        onClicked: Config.configPanelVisible = false
                    }
                }
            }

            Flickable {
                Layout.fillWidth: true
                Layout.fillHeight: true
                Layout.rightMargin: Config.sc(7)
                Layout.leftMargin: Config.sc(20)
                Layout.topMargin: Config.sc(20)
                clip: true
                boundsBehavior: Flickable.StopAtBounds
                contentWidth: width
                contentHeight: wifiColumn.height

                ScrollBar.vertical: ScrollBar {
                    policy: ScrollBar.AsNeeded
                }

                ColumnLayout {
                    id: wifiColumn
                    width: parent.width - Config.sc(17)
                    anchors.left: parent.left
                    spacing: Config.sc(20)

                    // WiFi Enable Toggle
                    Rectangle {
                        Layout.fillWidth: true
                        Layout.preferredHeight: Config.sc(60)
                        color: Config.foreground
                        radius: 15

                        Text {
                            anchors.left: parent.left
                            anchors.leftMargin: Config.sc(20)
                            anchors.verticalCenter: parent.verticalCenter
                            text: "WiFi"
                            color: Config.text
                            font.pixelSize: Config.scFont(15)
                            font.family: Config.fontFamily
                        }

                        ToggleSwitch {
                            id: wifiToggle
                            anchors.right: parent.right
                            anchors.rightMargin: Config.sc(20)
                            anchors.verticalCenter: parent.verticalCenter
                            checked: wifiPanel.wifiEnabled
                            onToggled: {
                                wifiPanel.wifiEnabled = !wifiPanel.wifiEnabled;
                            }
                        }
                    }

                    // Connected WiFi Section
                    Item {
                        Layout.fillWidth: true
                        Layout.preferredHeight: Config.sc(32)
                        visible: wifiPanel.wifiEnabled && configPanel.wifiConnected.length > 0

                        Text {
                            text: "Connected"
                            color: Config.text
                            font.pixelSize: Config.scFont(15)
                            font.family: Config.fontFamily
                            font.bold: true
                            anchors.verticalCenter: parent.verticalCenter
                        }
                    }

                    Rectangle {
                        Layout.fillWidth: true
                        Layout.preferredHeight: wifiConnectedList.count * Config.sc(60)
                        color: Config.foreground
                        radius: Config.sc(15)
                        visible: wifiPanel.wifiEnabled && configPanel.wifiConnected.length > 0

                        ListView {
                            id: wifiConnectedList
                            model: configPanel.wifiConnected
                            anchors.fill: parent
                            spacing: Config.sc(0)

                            delegate: Item {
                                id: wifiConnectedDelegate
                                width: parent.width
                                height: Config.sc(60)

                                property bool hovered: false

                                RowLayout {
                                    anchors.fill: parent
                                    spacing: Config.sc(12)

                                    Text {
                                        text: "\uf1eb"
                                        font.pixelSize: Config.scFont(18)
                                        font.family: Config.fontFamily
                                        color: Config.text
                                        Layout.leftMargin: Config.sc(20)
                                    }

                                    Column {
                                        Layout.fillWidth: true
                                        spacing: Config.sc(2)

                                        Text {
                                            text: modelData.name || "Unknown"
                                            font.pixelSize: Config.scFont(15)
                                            font.family: Config.fontFamily
                                            color: Config.text
                                        }

                                        Text {
                                            text: "Connected"
                                            font.pixelSize: Config.scFont(12)
                                            font.family: Config.fontFamily
                                            color: Config.text
                                            opacity: 0.6
                                        }
                                    }

                                    Item {
                                        Layout.fillWidth: true
                                    }

                                    Item {
                                        width: Config.sc(90)
                                        height: Config.sc(40)
                                        Layout.rightMargin: Config.sc(20)

                                        property bool pressed: false

                                        Text {
                                            text: "Disconnect"
                                            font.pixelSize: Config.scFont(13)
                                            font.family: Config.fontFamily
                                            color: Config.text
                                            anchors.centerIn: parent
                                            z: 1
                                        }

                                        MouseArea {
                                            anchors.fill: parent
                                            hoverEnabled: true
                                            cursorShape: Qt.PointingHandCursor
                                            onEntered: wifiConnectedDelegate.hovered = true
                                            onExited: wifiConnectedDelegate.hovered = false
                                            onPressed: parent.pressed = true
                                            onReleased: parent.pressed = false
                                            onClicked: {
                                                Buttoncommand.wifiDisconnect(modelData.name);
                                            }
                                        }

                                        Rectangle {
                                            anchors.fill: parent
                                            color: Config.closeColor
                                            radius: Config.sc(15)
                                            opacity: wifiConnectedDelegate.hovered ? 1 : 0.6
                                            scale: parent.pressed ? 0.9 : 1

                                            Behavior on opacity {
                                                NumberAnimation {
                                                    duration: 200
                                                    easing.type: Easing.InOutQuad
                                                }
                                            }

                                            Behavior on scale {
                                                NumberAnimation {
                                                    duration: 100
                                                    easing.type: Easing.InOutQuad
                                                }
                                            }
                                        }
                                    }
                                }

                                Rectangle {
                                    visible: index < wifiConnectedList.count - 1
                                    anchors.bottom: parent.bottom
                                    width: parent.width
                                    height: 1
                                    color: Config.progressColor
                                    opacity: 1
                                }
                            }
                        }
                    }

                    // Available Networks Section
                    Item {
                        Layout.fillWidth: true
                        Layout.preferredHeight: Config.sc(32)
                        visible: wifiPanel.wifiEnabled

                        Text {
                            text: "Available Networks"
                            color: Config.text
                            font.pixelSize: Config.scFont(15)
                            font.family: Config.fontFamily
                            font.bold: true
                            anchors.verticalCenter: parent.verticalCenter
                        }

                        Item {
                            id: wifiLoadingIcon
                            width: Config.sc(32)
                            height: Config.sc(32)
                            anchors.right: parent.right
                            anchors.verticalCenter: parent.verticalCenter

                            Text {
                                text: "\uf110"
                                font.pixelSize: Config.scFont(15)
                                font.bold: true
                                font.family: Config.fontFamily
                                color: Config.text
                                anchors.centerIn: parent
                            }

                            RotationAnimation {
                                target: wifiLoadingIcon
                                from: 0
                                to: 360
                                duration: 1000
                                loops: Animation.Infinite
                                running: configPanel.currentPanel === 3
                            }
                        }
                    }

                    Rectangle {
                        Layout.fillWidth: true
                        Layout.preferredHeight: Math.max(wifiScanList.count * Config.sc(60), Config.sc(60))
                        color: Config.foreground
                        radius: Config.sc(15)
                        visible: wifiPanel.wifiEnabled

                        Behavior on Layout.preferredHeight {
                            NumberAnimation {
                                duration: 150
                            }
                        }

                        Text {
                            text: "Scanning for networks..."
                            font.pixelSize: Config.scFont(15)
                            font.family: Config.fontFamily
                            color: Config.text
                            anchors.centerIn: parent
                            visible: wifiScanList.count === 0
                        }

                        ListView {
                            id: wifiScanList
                            model: configPanel.wifiList
                            anchors.fill: parent
                            spacing: Config.sc(0)
                            visible: wifiScanList.count > 0

                            delegate: Item {
                                id: wifiScanDelegate
                                width: parent.width
                                height: Config.sc(60)

                                property bool hovered: false

                                RowLayout {
                                    anchors.fill: parent
                                    spacing: Config.sc(12)

                                    // Signal strength icon
                                    Text {
                                        text: {
                                            let signal = parseInt(modelData.signal);
                                            if (signal >= 80)
                                                return "\uf1eb";
                                            else if (signal >= 60)
                                                return "\uf1eb";
                                            else if (signal >= 40)
                                                return "\uf1eb";
                                            else
                                                return "\uf1eb";
                                        }
                                        font.pixelSize: Config.scFont(18)
                                        font.family: Config.fontFamily
                                        color: {
                                            let signal = parseInt(modelData.signal);
                                            if (signal >= 80)
                                                return Config.text;
                                            else if (signal >= 60)
                                                return Config.text;
                                            else
                                                return Config.text;
                                        }
                                        opacity: {
                                            let signal = parseInt(modelData.signal);
                                            if (signal >= 80)
                                                return 1;
                                            else if (signal >= 60)
                                                return 0.8;
                                            else if (signal >= 40)
                                                return 0.6;
                                            else
                                                return 0.4;
                                        }
                                        Layout.leftMargin: Config.sc(20)
                                    }

                                    Column {
                                        Layout.fillWidth: true
                                        spacing: Config.sc(2)

                                        Text {
                                            text: modelData.name || "Unknown"
                                            font.pixelSize: Config.scFont(15)
                                            font.family: Config.fontFamily
                                            color: Config.text
                                        }

                                        Text {
                                            text: modelData.security || "Open"
                                            font.pixelSize: Config.scFont(12)
                                            font.family: Config.fontFamily
                                            color: Config.text
                                            opacity: 0.6
                                        }
                                    }

                                    Item {
                                        Layout.fillWidth: true
                                    }

                                    // Signal strength
                                    Text {
                                        text: (modelData.signal || "0") + "%"
                                        font.pixelSize: Config.scFont(13)
                                        font.family: Config.fontFamily
                                        color: Config.text
                                        opacity: 0.6
                                        Layout.rightMargin: Config.sc(16)
                                    }

                                    Item {
                                        width: Config.sc(90)
                                        height: Config.sc(40)
                                        Layout.rightMargin: Config.sc(20)

                                        property bool pressed: false

                                        Text {
                                            text: "Connect"
                                            font.pixelSize: Config.scFont(15)
                                            font.family: Config.fontFamily
                                            color: Config.text
                                            anchors.centerIn: parent
                                            z: 1
                                        }

                                        MouseArea {
                                            anchors.fill: parent
                                            hoverEnabled: true
                                            cursorShape: Qt.PointingHandCursor
                                            onEntered: wifiScanDelegate.hovered = true
                                            onExited: wifiScanDelegate.hovered = false
                                            onPressed: parent.pressed = true
                                            onReleased: parent.pressed = false
                                            onClicked: {
                                                Config.selectedWifi = {
                                                    name: modelData.name,
                                                    signal: modelData.signal,
                                                    security: modelData.security
                                                };
                                                Config.wifiPasswordPopupVisible = true;
                                            }
                                        }

                                        Rectangle {
                                            anchors.fill: parent
                                            color: Config.textHover
                                            radius: Config.sc(15)
                                            opacity: wifiScanDelegate.hovered ? 1 : 0.8
                                            scale: parent.pressed ? 0.9 : 1

                                            Behavior on opacity {
                                                NumberAnimation {
                                                    duration: 200
                                                    easing.type: Easing.InOutQuad
                                                }
                                            }

                                            Behavior on scale {
                                                NumberAnimation {
                                                    duration: 100
                                                    easing.type: Easing.InOutQuad
                                                }
                                            }
                                        }
                                    }
                                }

                                Rectangle {
                                    visible: index < wifiScanList.count - 1
                                    anchors.bottom: parent.bottom
                                    width: parent.width
                                    height: 1
                                    color: Config.progressColor
                                    opacity: 1
                                }
                            }
                        }
                    }

                    Item {
                        Layout.fillHeight: true
                    }
                }
            }
        }
    }

    // Mode Selector (Dropdown)
    component ModeSelector: Item {
        id: modeSelector
        property var modes: []
        property string currentMode: ""
        property int selectedIndex: 0
        property bool expanded: false
        signal modeSelected(string mode)

        width: Config.sc(160)
        height: Config.sc(32)

        // Selector button
        Rectangle {
            anchors.fill: parent
            color: Config.background
            border.color: Config.progressColor
            border.width: 1
            radius: Config.sc(6)

            RowLayout {
                anchors.fill: parent
                anchors.leftMargin: Config.sc(10)
                anchors.rightMargin: Config.sc(10)

                Text {
                    text: currentMode
                    color: Config.text
                    font.pixelSize: Config.scFont(13)
                    font.family: Config.fontFamily
                    Layout.fillWidth: true
                    elide: Text.ElideRight
                }

                Text {
                    text: expanded ? "\uf077" : "\uf078"
                    color: Config.text
                    font.pixelSize: Config.scFont(12)
                    font.family: Config.fontFamily
                }
            }

            MouseArea {
                anchors.fill: parent
                cursorShape: Qt.PointingHandCursor
                onClicked: {
                    if (modeSelector.expanded) {
                        dropdownPopup.close();
                    } else {
                        dropdownPopup.open();
                    }
                }
            }
        }

        // Dropdown popup (using Popup to avoid clipping issues)
        Popup {
            id: dropdownPopup
            x: 0
            y: modeSelector.height + Config.sc(2)
            width: modeSelector.width
            height: Config.sc(32) * 4  // Max 4 items visible
            padding: 0
            background: Rectangle {
                color: Config.background
                border.color: Config.progressColor
                border.width: 1
                radius: Config.sc(6)
            }
            closePolicy: Popup.CloseOnEscape | Popup.CloseOnPressOutsideParent
            onOpened: modeSelector.expanded = true
            onClosed: modeSelector.expanded = false

            Flickable {
                anchors.fill: parent
                anchors.margins: Config.sc(2)
                clip: true
                boundsBehavior: Flickable.StopAtBounds
                contentWidth: width
                contentHeight: modeListColumn.height

                ScrollBar.vertical: ScrollBar {
                    policy: ScrollBar.AsNeeded
                }

                Column {
                    id: modeListColumn
                    width: parent.width
                    spacing: 0

                    Repeater {
                        model: modeSelector.modes

                        Rectangle {
                            width: dropdownPopup.width - Config.sc(4)
                            height: Config.sc(32)
                            color: modeItemMouseArea.containsMouse ? Config.textselect : "transparent"
                            radius: Config.sc(4)

                            Behavior on color {
                                ColorAnimation {
                                    duration: 200
                                    easing.type: Easing.InOutQuad
                                }
                            }

                            RowLayout {
                                anchors.fill: parent
                                anchors.leftMargin: Config.sc(10)
                                anchors.rightMargin: Config.sc(10)

                                Text {
                                    text: modelData
                                    color: Config.text
                                    font.pixelSize: Config.scFont(13)
                                    font.family: Config.fontFamily
                                    Layout.fillWidth: true
                                    elide: Text.ElideRight
                                }

                                Text {
                                    text: modelData === modeSelector.currentMode ? "\uf00c" : ""
                                    color: Config.textHover
                                    font.pixelSize: Config.scFont(12)
                                    font.family: Config.fontFamily
                                    visible: modelData === modeSelector.currentMode
                                }
                            }

                            MouseArea {
                                id: modeItemMouseArea
                                anchors.fill: parent
                                hoverEnabled: true
                                cursorShape: Qt.PointingHandCursor
                                onClicked: {
                                    modeSelector.currentMode = modelData;
                                    dropdownPopup.close();
                                    modeSelector.modeSelected(modelData);
                                }
                            }
                        }
                    }
                }
            }
        }
    }

    // Display Panel
    component DisplayPanel: Rectangle {
        id: displayPanel
        color: Config.background
        topRightRadius: Config.sc(35)
        bottomRightRadius: Config.sc(35)

        property var setMonitor: []
        property string setPriScreen: ""

        // Use Config.priScreen directly for primary monitor check
        function isPrimary(name) {
            // 如果有选中的主屏幕，使用它；否则使用 Config.priScreen
            let target = displayPanel.setPriScreen !== "" ? displayPanel.setPriScreen : Config.priScreen;
            return name === target;
        }

        Component.onCompleted: {
            monitorInfo();
        }

        function monitorInfo() {
            let info = [];

            for (let i = 0; i < configPanel.monitors.length; i++) {
                info.push({
                    name: configPanel.monitors[i].name,
                    currentMode: configPanel.monitors[i].currentMode,
                    scale: configPanel.monitors[i].scale
                });
            }

            setMonitor = info;
        }

        ColumnLayout {
            anchors.fill: parent
            spacing: 0

            // Header
            RowLayout {
                Layout.fillWidth: true
                Layout.leftMargin: Config.sc(20)
                Layout.rightMargin: Config.sc(20)
                Layout.topMargin: Config.sc(20)
                spacing: Config.sc(20)

                Text {
                    text: "Display"
                    color: Config.text
                    font.pixelSize: Config.scFont(20)
                    font.bold: true
                    font.family: Config.fontFamily
                }

                Item {
                    Layout.fillWidth: true
                }

                Item {
                    Layout.preferredWidth: Config.sc(60)
                    Layout.preferredHeight: Config.sc(32)

                    property bool pressed: false
                    property bool hovered: false

                    Rectangle {
                        anchors.fill: parent
                        color: Config.textHover
                        radius: height / 2
                        scale: parent.pressed ? 0.9 : 1
                        opacity: parent.hovered ? 1 : 0.8

                        Behavior on scale {
                            NumberAnimation {
                                duration: 100
                                easing.type: Easing.InOutQuad
                            }
                        }

                        Behavior on opacity {
                            NumberAnimation {
                                duration: 200
                                easing.type: Easing.InOutQuad
                            }
                        }

                        Text {
                            anchors.centerIn: parent
                            text: "Apply"
                            color: Config.text
                            font.pixelSize: Config.scFont(15)
                            font.family: Config.fontFamily
                        }
                    }

                    MouseArea {
                        anchors.fill: parent
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
                        onPressed: parent.pressed = true
                        onReleased: parent.pressed = false
                        onEntered: parent.hovered = true
                        onExited: parent.hovered = false
                        onClicked: {
                            if (displayPanel.setMonitor.length > 0) {
                                Buttoncommand.setMonitorExec(displayPanel.setMonitor);
                            }

                            if (displayPanel.setPriScreen !== "") {
                                let width = "";
                                let height = "";

                                // 从 monitors 数组中获取屏幕信息
                                for (let i = 0; i < displayPanel.setMonitor.length; i++) {
                                    if (displayPanel.setMonitor[i].name === displayPanel.setPriScreen) {
                                        let modeMatch = displayPanel.setMonitor[i].currentMode.match(/(\d+)x(\d+)/);
                                        if (modeMatch) {
                                            width = parseInt(modeMatch[1]);
                                            height = parseInt(modeMatch[2]);
                                            break;
                                        }
                                    }
                                }

                                // 使用小写的 screenWidth/screenHeight
                                Config.screenWidth = width;
                                Config.screenHeight = height;
                                Config.priScreen = displayPanel.setPriScreen;
                                console.warn("Screen size:", Config.screenWidth, Config.screenHeight);
                            }
                        }
                    }
                }

                Item {
                    Layout.preferredWidth: Config.sc(32)
                    Layout.preferredHeight: Config.sc(32)

                    property bool isHovered: false

                    Rectangle {
                        anchors.fill: parent
                        color: Config.foreground
                        radius: height / 2
                        opacity: parent.isHovered ? 1 : 0

                        Behavior on opacity {
                            NumberAnimation {
                                duration: 200
                                easing.type: Easing.InOutQuad
                            }
                        }
                    }

                    Text {
                        anchors.centerIn: parent
                        text: "\uf00d"
                        color: Config.text
                        font.pixelSize: Config.scFont(15)
                        font.bold: true
                        font.family: Config.fontFamily
                    }

                    MouseArea {
                        anchors.fill: parent
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
                        onEntered: parent.isHovered = true
                        onExited: parent.isHovered = false
                        onClicked: Config.configPanelVisible = false
                    }
                }
            }

            // Scrollable content
            Flickable {
                Layout.fillWidth: true
                Layout.fillHeight: true
                Layout.rightMargin: Config.sc(7)
                Layout.leftMargin: Config.sc(20)
                Layout.topMargin: Config.sc(20)
                clip: true
                boundsBehavior: Flickable.StopAtBounds
                contentWidth: width
                contentHeight: displayColumn.height

                ScrollBar.vertical: ScrollBar {
                    policy: ScrollBar.AsNeeded
                }

                ColumnLayout {
                    id: displayColumn
                    width: parent.width - Config.sc(17)
                    anchors.left: parent.left
                    spacing: Config.sc(20)

                    Repeater {
                        model: configPanel.monitors

                        ColumnLayout {
                            Layout.fillWidth: true
                            spacing: Config.sc(10)

                            // Monitor name section header
                            Item {
                                Layout.fillWidth: true
                                Layout.preferredHeight: Config.sc(32)

                                Text {
                                    text: modelData.name
                                    color: Config.text
                                    font.pixelSize: Config.scFont(15)
                                    font.family: Config.fontFamily
                                    font.bold: true
                                    anchors.verticalCenter: parent.verticalCenter
                                }

                                Text {
                                    text: displayPanel.isPrimary(modelData.name) ? "Primary" : ""
                                    color: Config.text
                                    font.pixelSize: Config.scFont(12)
                                    font.family: Config.fontFamily
                                    visible: displayPanel.isPrimary(modelData.name)
                                    anchors.verticalCenter: parent.verticalCenter
                                    anchors.right: parent.right
                                }
                            }

                            // Monitor settings card
                            Rectangle {
                                Layout.fillWidth: true
                                Layout.preferredHeight: monitorSettingsColumn.height
                                color: Config.foreground
                                radius: Config.sc(15)

                                Column {
                                    id: monitorSettingsColumn
                                    width: parent.width

                                    // Resolution/Mode
                                    Item {
                                        width: parent.width
                                        height: Config.sc(60)

                                        RowLayout {
                                            anchors.fill: parent
                                            anchors.leftMargin: Config.sc(20)
                                            anchors.rightMargin: Config.sc(20)

                                            Text {
                                                text: "Mode"
                                                color: Config.text
                                                font.pixelSize: Config.scFont(15)
                                                font.family: Config.fontFamily
                                                Layout.alignment: Qt.AlignVCenter
                                            }

                                            Item {
                                                Layout.fillWidth: true
                                            }

                                            ModeSelector {
                                                Layout.alignment: Qt.AlignVCenter
                                                modes: modelData.modes
                                                currentMode: modelData.currentMode
                                                onModeSelected: function (mode) {
                                                    for (let i = 0; i < displayPanel.setMonitor.length; i++) {
                                                        if (displayPanel.setMonitor[i].name === modelData.name) {
                                                            displayPanel.setMonitor[i].currentMode = mode;
                                                            break;
                                                        }
                                                    }
                                                }
                                            }
                                        }

                                        Rectangle {
                                            anchors.bottom: parent.bottom
                                            width: parent.width
                                            height: 1
                                            color: Config.progressColor
                                            opacity: 1
                                        }
                                    }

                                    // Scale
                                    Item {
                                        width: parent.width
                                        height: Config.sc(60)

                                        RowLayout {
                                            anchors.fill: parent
                                            anchors.leftMargin: Config.sc(20)
                                            anchors.rightMargin: Config.sc(20)

                                            Text {
                                                text: "Scale"
                                                color: Config.text
                                                font.pixelSize: Config.scFont(15)
                                                font.family: Config.fontFamily
                                                Layout.alignment: Qt.AlignVCenter
                                            }

                                            Item {
                                                Layout.fillWidth: true
                                            }

                                            NumberField {
                                                Layout.alignment: Qt.AlignVCenter
                                                value: modelData.scale || "1"
                                                suffix: "x"
                                                onValueChanged: {
                                                    for (let i = 0; i < displayPanel.setMonitor.length; i++) {
                                                        if (displayPanel.setMonitor[i].name === modelData.name) {
                                                            displayPanel.setMonitor[i].scale = value;
                                                            break;
                                                        }
                                                    }
                                                }
                                            }
                                        }

                                        Rectangle {
                                            anchors.bottom: parent.bottom
                                            width: parent.width
                                            height: 1
                                            color: Config.progressColor
                                            opacity: 1
                                        }
                                    }

                                    // Set Primary Monitor
                                    Item {
                                        width: parent.width
                                        height: Config.sc(60)

                                        RowLayout {
                                            anchors.fill: parent
                                            anchors.leftMargin: Config.sc(20)
                                            anchors.rightMargin: Config.sc(20)

                                            Text {
                                                text: "Set Primary Monitor"
                                                color: Config.text
                                                font.pixelSize: Config.scFont(15)
                                                font.family: Config.fontFamily
                                                Layout.alignment: Qt.AlignVCenter
                                            }

                                            Item {
                                                Layout.fillWidth: true
                                            }

                                            ToggleSwitch {
                                                Layout.alignment: Qt.AlignVCenter
                                                bindable: true
                                                checked: displayPanel.isPrimary(modelData.name)
                                                onToggled: {
                                                    displayPanel.setPriScreen = modelData.name;
                                                }
                                            }
                                        }
                                    }
                                }
                            }
                        }
                    }

                    Item {
                        Layout.fillHeight: true
                    }
                }
            }
        }
    }
}
