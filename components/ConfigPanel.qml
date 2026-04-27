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
            if (Quickshell.screens[i].name === Config.priScreen)
                return Quickshell.screens[i];
        }
        return Quickshell.screens[0];
    }

    onVisibleChanged: {
        if (!visible) Config.configPanelVisible = false;
        if (visible) {
            bluetoothListProc.running = true;
            wifiListProc.running = true;
        }
    }

    // ── Process objects ──────────────────────────────────────────────

    Process {
        id: wifiListProc
        command: ["nmcli", "-t", "-f", "IN-USE,SSID,SIGNAL,SECURITY", "device", "wifi", "list"]
        running: false
        stdout: StdioCollector {
            onStreamFinished: {
                let text = this.text;
                let scanList = [];
                let connected = [];
                for (let line of text.split("\n")) {
                    if (!line.trim()) continue;
                    let parts = line.split(":");
                    if (parts.length < 3) continue;
                    let name = parts[1] || "Unknown";
                    if (!name) continue;
                    let item = { name: name, signal: parts[2] || "0", security: parts[3] || "" };
                    if (parts[0] === "*") connected.push(item);
                    else scanList.push(item);
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
                    let devices = [];
                    for (let line of this.text.split("\n")) {
                        let parts = line.split(" ");
                        if (parts.length >= 3)
                            devices.push({ address: parts[1], name: parts.slice(2).join(" ") });
                    }
                    configPanel.connectedModel = devices;
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
                try { configPanel.wallPaperModel = JSON.parse(this.text); }
                catch (e) { console.warn("Failed to parse wallpaper data:", this.text); }
            }
        }
    }

    Process {
        id: bluetoothListProc
        command: ["bluetoothctl", "--timeout", "10", "scan", "on"]
        running: false
        stdout: StdioCollector {
            onStreamFinished: {
                try {
                    let text = this.text.replace(/\x1b\[[0-9;]*m/g, "");
                    let devices = [];
                    for (let line of text.split("\n")) {
                        line = line.trim();
                        if (!line.startsWith("[NEW] Device")) continue;
                        let parts = line.split(" ");
                        if (parts.length >= 4) {
                            let addr = parts[2];
                            let name = parts.slice(3).join(" ");
                            if (name.replace(/-/g, ":") === addr) name = "Unknown";
                            devices.push({ address: addr, name: name });
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
                    let lines = this.text.split("\n");
                    let monitors = [];
                    let info = null;
                    let inBlock = false;
                    for (let line of lines) {
                        let t = line.trim();
                        if (t.startsWith("Output")) {
                            if (info && info.name) monitors.push(info);
                            info = { name: "", modes: [], currentMode: "", scale: "1" };
                            let m = t.match(/Output\s+"[^"]*"\s+\(([^)]+)\)/);
                            if (m) info.name = m[1];
                            inBlock = false;
                        } else if (t.startsWith("Scale:") && info) {
                            let m = t.match(/Scale:\s*([\d.]+)/);
                            if (m) info.scale = m[1];
                        } else if (t.startsWith("Available modes:")) {
                            inBlock = true;
                        } else if (inBlock) {
                            let m = t.match(/(\d+x\d+@\d+\.\d+)/);
                            if (m) {
                                if (t.includes("current")) info.currentMode = m[1];
                                else info.modes.push(m[1]);
                            }
                        } else if (t === "") {
                            inBlock = false;
                        }
                    }
                    if (info && info.name) monitors.push(info);
                    configPanel.monitors = monitors;
                } catch (e) {
                    console.warn("Failed to parse niri output:", e);
                }
            }
        }
    }

    // ── Timers ────────────────────────────────────────────────────────

    Timer { interval: 11000; running: configPanel.currentPanel === 2; repeat: true; onTriggered: bluetoothListProc.running = true; }
    Timer { interval: 5000;  running: configPanel.currentPanel === 3; repeat: true; onTriggered: wifiListProc.running = true; }
    Timer { id: refreshConnectedTimer;    interval: 500;  repeat: false; onTriggered: bluetoothConnectedProcess.running = true; }
    Timer { id: refreshBluetoothTimer;    interval: 5000; repeat: false; onTriggered: { bluetoothConnectedProcess.running = true; bluetoothListProc.running = true; } }
    Timer { id: refreshWifiTimer;         interval: 3000; repeat: false; onTriggered: wifiListProc.running = true; }

    Component.onCompleted: {
        wallPapersList.running = true;
        bluetoothConnectedProcess.running = true;
        wifiListProc.running = true;
    }

    // ── Main Layout ──────────────────────────────────────────────────

    Item {
        anchors.centerIn: parent
        width: Config.sc(900)
        height: Config.sc(650)

        RowLayout {
            anchors.fill: parent
            spacing: 0

            // Sidebar
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

                    SidebarItem { icon: ""; label: "Appearance"; isActive: configPanel.currentPanel === 0; onClicked: configPanel.currentPanel = 0; }
                    SidebarItem { icon: ""; label: "Wallpaper";  isActive: configPanel.currentPanel === 1; onClicked: configPanel.currentPanel = 1; }
                    SidebarItem { icon: ""; label: "Bluetooth";  isActive: configPanel.currentPanel === 2; onClicked: configPanel.currentPanel = 2; }
                    SidebarItem { icon: ""; label: "WiFi";       isActive: configPanel.currentPanel === 3; onClicked: configPanel.currentPanel = 3; }
                    SidebarItem { icon: "\uf108"; label: "Display"; isActive: configPanel.currentPanel === 4; onClicked: configPanel.currentPanel = 4; }

                    Item { Layout.fillHeight: true; }
                }
            }

            // Content Area
            Item {
                Layout.fillWidth: true
                Layout.fillHeight: true

                Loader {
                    anchors.fill: parent
                    sourceComponent: {
                        if (configPanel.currentPanel === 0) return appearancePanelComp;
                        if (configPanel.currentPanel === 1) return wallpaperPanelComp;
                        if (configPanel.currentPanel === 2) return bluetoothPanelComp;
                        if (configPanel.currentPanel === 3) return wifiPanelComp;
                        if (configPanel.currentPanel === 4) return displayPanelComp;
                        return null;
                    }

                    Component { id: appearancePanelComp; AppearancePanel {} }
                    Component { id: wallpaperPanelComp;  WallpaperPanel {} }
                    Component { id: bluetoothPanelComp;  BlueToothPanel {} }
                    Component { id: wifiPanelComp;       WifiPanel {} }
                    Component { id: displayPanelComp;    DisplayPanel {} }
                }
            }
        }
    }

    // ═══════════════════════════════════════════════════════════════════
    // SHARED COMPONENTS
    // ═══════════════════════════════════════════════════════════════════

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

            Text { text: icon; color: Config.text; font.pixelSize: Config.scFont(18); font.bold: true; font.family: Config.fontFamily; }
            Text { text: label; color: Config.text; font.pixelSize: Config.scFont(15); font.bold: true; font.family: Config.fontFamily; Layout.fillWidth: true; Layout.topMargin: Config.sc(3); }
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

    component ToggleSwitch: Rectangle {
        id: toggleSwitch
        property bool checked: true
        property bool bindable: false
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
            Behavior on x { NumberAnimation { duration: 150; easing.type: Easing.InOutQuad; } }
        }

        MouseArea {
            anchors.fill: parent
            cursorShape: Qt.PointingHandCursor
            onClicked: {
                if (!toggleSwitch.bindable) toggleSwitch.checked = !toggleSwitch.checked;
                toggleSwitch.toggled();
            }
        }
    }

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
                background: Rectangle { color: "transparent"; }
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

    component CloseButton: Item {
        signal clicked

        implicitWidth: Config.sc(32)
        implicitHeight: Config.sc(32)

        property bool isHovered: false

        Rectangle {
            anchors.fill: parent
            color: Config.foreground
            radius: height / 2
            opacity: parent.isHovered ? 1 : 0
            Behavior on opacity { NumberAnimation { duration: 200; easing.type: Easing.InOutQuad; } }
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
            onClicked: parent.clicked()
        }
    }

    component ActionButton: Item {
        property alias text: label.text
        property color btnColor: Config.textHover
        property real normalOpacity: 0.8
        signal clicked

        implicitWidth: Config.sc(90)
        implicitHeight: Config.sc(40)

        property bool hovered: false
        property bool pressed: false

        Text {
            id: label
            anchors.centerIn: parent
            font.pixelSize: Config.scFont(text.length > 10 ? 13 : 15)
            font.family: Config.fontFamily
            color: Config.text
            z: 1
        }

        Rectangle {
            anchors.fill: parent
            color: btnColor
            radius: Config.sc(15)
            opacity: hovered ? 1 : normalOpacity
            scale: pressed ? 0.9 : 1
            Behavior on opacity { NumberAnimation { duration: 200; easing.type: Easing.InOutQuad; } }
            Behavior on scale { NumberAnimation { duration: 100; easing.type: Easing.InOutQuad; } }
        }

        MouseArea {
            anchors.fill: parent
            hoverEnabled: true
            cursorShape: Qt.PointingHandCursor
            onEntered: parent.hovered = true
            onExited: parent.hovered = false
            onPressed: parent.pressed = true
            onReleased: parent.pressed = false
            onClicked: parent.clicked()
        }
    }

    component SettingRow: Item {
        property string label: ""
        property real rowOpacity: 1
        property bool showSeparator: true
        default property alias content: rowChildren.data

        width: parent ? parent.width : 0
        height: Config.sc(60)
        opacity: rowOpacity

        RowLayout {
            id: rowChildren
            anchors.fill: parent
            anchors.leftMargin: Config.sc(20)
            anchors.rightMargin: Config.sc(20)

            Text {
                text: label
                color: Config.text
                font.pixelSize: Config.scFont(15)
                font.family: Config.fontFamily
            }

            Item { Layout.fillWidth: true; }
        }

        Rectangle {
            anchors.bottom: parent.bottom
            width: parent.width
            height: 1
            color: Config.progressColor
            visible: showSeparator
        }
    }

    component SectionHeader: Item {
        property string title: ""

        Layout.fillWidth: true
        Layout.preferredHeight: Config.sc(32)

        Text {
            text: title
            color: Config.text
            font.pixelSize: Config.scFont(15)
            font.family: Config.fontFamily
            font.bold: true
            anchors.verticalCenter: parent.verticalCenter
        }
    }

    component SectionCard: Rectangle {
        default property alias content: cardContent.data

        Layout.fillWidth: true
        Layout.preferredHeight: cardContent.height
        color: Config.foreground
        radius: Config.sc(15)

        Column { id: cardContent; width: parent.width; }
    }

    // ═══════════════════════════════════════════════════════════════════
    // APPEARANCE PANEL
    // ═══════════════════════════════════════════════════════════════════

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

                Item { Layout.fillWidth: true; }

                ActionButton {
                    text: "Apply"
                    Layout.preferredWidth: Config.sc(60)
                    Layout.preferredHeight: Config.sc(32)
                    onClicked: Buttoncommand.niriSettingExec(Config.niriInfo);
                }

                CloseButton { onClicked: Config.configPanelVisible = false; }
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
                contentHeight: appearanceColumn.height
                ScrollBar.vertical: ScrollBar { policy: ScrollBar.AsNeeded; }

                ColumnLayout {
                    id: appearanceColumn
                    width: parent.width - Config.sc(17)
                    anchors.left: parent.left
                    spacing: Config.sc(20)

                    // ── Window ──
                    SectionHeader { title: "Window"; }

                    SectionCard {
                        SettingRow { label: "Gaps"
                            NumberField {
                                value: Config.niriInfo ? Config.niriInfo["layout"]["gaps"] : "20"
                                suffix: "px"
                                onValueChanged: Config.niriInfo["layout"]["gaps"] = value;
                            }
                        }
                        SettingRow { label: "Corner Radius"; showSeparator: false
                            NumberField {
                                value: Config.niriInfo && Config.niriInfo["corner_radius"] ? Config.niriInfo["corner_radius"]["radius"] : "15"
                                suffix: "px"
                                onValueChanged: Config.niriInfo["corner_radius"]["radius"] = value;
                            }
                        }
                    }

                    // ── Focus Ring ──
                    SectionHeader { title: "Focus Ring"; }

                    SectionCard {
                        SettingRow { label: "Enable"
                            ToggleSwitch {
                                id: focusRingToggle
                                checked: Config.niriInfo ? Config.niriInfo["focus-ring"]["enable"] : true
                                onToggled: Config.niriInfo["focus-ring"]["enable"] = checked;
                            }
                        }
                        SettingRow { label: "Width"; rowOpacity: focusRingToggle.checked ? 1 : 0.5
                            NumberField {
                                value: Config.niriInfo ? Config.niriInfo["focus-ring"]["width"] : "4"
                                suffix: "px"
                                enabled: focusRingToggle.checked
                                onValueChanged: Config.niriInfo["focus-ring"]["width"] = value;
                            }
                        }
                        SettingRow { label: "Color"; rowOpacity: focusRingToggle.checked ? 1 : 0.5; showSeparator: false
                            RowLayout { spacing: Config.sc(8)
                                Rectangle {
                                    width: Config.sc(20); height: Config.sc(20); radius: height / 2
                                    color: focusRingColorInput.text; border.width: 1; border.color: Config.progressColor;
                                }
                                Rectangle {
                                    width: Config.sc(90); height: Config.sc(32)
                                    color: Config.background; border.color: Config.progressColor; border.width: 1; radius: Config.sc(6);
                                    TextField {
                                        id: focusRingColorInput
                                        anchors.fill: parent; anchors.leftMargin: Config.sc(8); anchors.rightMargin: Config.sc(8)
                                        text: Config.niriInfo ? Config.niriInfo["focus-ring"]["color"] : "#7fc8ff"
                                        color: Config.text; font.pixelSize: Config.scFont(15); font.family: Config.fontFamily
                                        background: Rectangle { color: "transparent"; }
                                        selectByMouse: true; enabled: focusRingToggle.checked
                                        onTextChanged: Config.niriInfo["focus-ring"]["color"] = text;
                                    }
                                }
                            }
                        }
                    }

                    // ── Border ──
                    SectionHeader { title: "Border"; }

                    SectionCard {
                        SettingRow { label: "Enable"
                            ToggleSwitch {
                                id: borderToggle
                                checked: Config.niriInfo ? Config.niriInfo["border"]["enable"] : true
                                onToggled: Config.niriInfo["border"]["enable"] = checked;
                            }
                        }
                        SettingRow { label: "Width"; rowOpacity: borderToggle.checked ? 1 : 0.5
                            NumberField {
                                value: Config.niriInfo ? Config.niriInfo["border"]["width"] : "4"
                                suffix: "px"
                                enabled: borderToggle.checked
                                onValueChanged: Config.niriInfo["border"]["width"] = value;
                            }
                        }
                        SettingRow { label: "Color"; rowOpacity: borderToggle.checked ? 1 : 0.5; showSeparator: false
                            RowLayout { spacing: Config.sc(8)
                                Rectangle {
                                    width: Config.sc(20); height: Config.sc(20); radius: height / 2
                                    color: borderColorInput.text; border.width: 1; border.color: Config.progressColor;
                                }
                                Rectangle {
                                    width: Config.sc(90); height: Config.sc(32)
                                    color: Config.background; border.color: Config.progressColor; border.width: 1; radius: Config.sc(6);
                                    TextField {
                                        id: borderColorInput
                                        anchors.fill: parent; anchors.leftMargin: Config.sc(8); anchors.rightMargin: Config.sc(8)
                                        text: Config.niriInfo ? Config.niriInfo["border"]["color"] : "#ffc87f"
                                        color: Config.text; font.pixelSize: Config.scFont(15); font.family: Config.fontFamily
                                        background: Rectangle { color: "transparent"; }
                                        selectByMouse: true; enabled: borderToggle.checked
                                        onTextChanged: Config.niriInfo["border"]["color"] = text;
                                    }
                                }
                            }
                        }
                    }

                    // ── Shadow ──
                    SectionHeader { title: "Shadow"; }

                    SectionCard {
                        SettingRow { label: "Enable"
                            ToggleSwitch {
                                id: shadowToggle
                                checked: Config.niriInfo ? Config.niriInfo["shadow"]["enable"] : false
                                onToggled: Config.niriInfo["shadow"]["enable"] = checked;
                            }
                        }
                        SettingRow { label: "Softness"; rowOpacity: shadowToggle.checked ? 1 : 0.5
                            NumberField {
                                value: Config.niriInfo ? Config.niriInfo["shadow"]["softness"] : "30"
                                suffix: "px"
                                enabled: shadowToggle.checked
                                onValueChanged: Config.niriInfo["shadow"]["softness"] = value;
                            }
                        }
                        SettingRow { label: "Spread"; rowOpacity: shadowToggle.checked ? 1 : 0.5
                            NumberField {
                                value: Config.niriInfo ? Config.niriInfo["shadow"]["spread"] : "5"
                                suffix: "px"
                                enabled: shadowToggle.checked
                                onValueChanged: Config.niriInfo["shadow"]["spread"] = value;
                            }
                        }
                        SettingRow { label: "Offset"; rowOpacity: shadowToggle.checked ? 1 : 0.5
                            RowLayout { spacing: Config.sc(8)
                                NumberField {
                                    value: Config.niriInfo && Config.niriInfo["shadow"]["offset"] ? Config.niriInfo["shadow"]["offset"]["x"] : "0"
                                    suffix: "X"; enabled: shadowToggle.checked
                                    onValueChanged: Config.niriInfo["shadow"]["offset"]["x"] = value;
                                }
                                NumberField {
                                    value: Config.niriInfo && Config.niriInfo["shadow"]["offset"] ? Config.niriInfo["shadow"]["offset"]["y"] : "5"
                                    suffix: "Y"; enabled: shadowToggle.checked
                                    onValueChanged: Config.niriInfo["shadow"]["offset"]["y"] = value;
                                }
                            }
                        }
                        SettingRow { label: "Color"; rowOpacity: shadowToggle.checked ? 1 : 0.5; showSeparator: false
                            RowLayout { spacing: Config.sc(8)
                                Rectangle {
                                    width: Config.sc(20); height: Config.sc(20); radius: height / 2
                                    color: shadowColorInput.text; border.width: 1; border.color: Config.progressColor;
                                }
                                Rectangle {
                                    width: Config.sc(90); height: Config.sc(32)
                                    color: Config.background; border.color: Config.progressColor; border.width: 1; radius: Config.sc(6);
                                    TextField {
                                        id: shadowColorInput
                                        anchors.fill: parent; anchors.leftMargin: Config.sc(8); anchors.rightMargin: Config.sc(8)
                                        text: Config.niriInfo ? Config.niriInfo["shadow"]["color"] : "#000000"
                                        color: Config.text; font.pixelSize: Config.scFont(15); font.family: Config.fontFamily
                                        background: Rectangle { color: "transparent"; }
                                        selectByMouse: true; enabled: shadowToggle.checked
                                        onTextChanged: Config.niriInfo["shadow"]["color"] = text;
                                    }
                                }
                            }
                        }
                    }

                    // ── Animations ──
                    SectionHeader { title: "Animations"; }

                    SectionCard {
                        SettingRow { label: "Enable"
                            ToggleSwitch {
                                id: animToggle
                                checked: Config.niriInfo ? Config.niriInfo["animations"]["enable"] : true
                                onToggled: Config.niriInfo["animations"]["enable"] = checked;
                            }
                        }
                        SettingRow { label: "Slowdown"; rowOpacity: animToggle.checked ? 1 : 0.5; showSeparator: false
                            NumberField {
                                value: Config.niriInfo && Config.niriInfo["animations"] ? Config.niriInfo["animations"]["slowdown"] : "1.0"
                                suffix: "x"
                                enabled: animToggle.checked
                                onValueChanged: Config.niriInfo["animations"]["slowdown"] = value;
                            }
                        }
                    }

                    // ── Extra Gaps ──
                    SectionHeader { title: "Extra Gaps"; }

                    SectionCard {
                        SettingRow { label: "Enable"
                            ToggleSwitch {
                                id: extraGapsToggle
                                checked: Config.niriInfo ? Config.niriInfo["struts"]["enabled"] : false
                                onToggled: Config.niriInfo["struts"]["enabled"] = checked;
                            }
                        }
                        SettingRow { label: "Top";    rowOpacity: extraGapsToggle.checked ? 1 : 0.5
                            NumberField {
                                value: Config.niriInfo && Config.niriInfo["struts"] ? Config.niriInfo["struts"]["top"] : "0"
                                suffix: "px"; enabled: extraGapsToggle.checked
                                onValueChanged: Config.niriInfo["struts"]["top"] = value;
                            }
                        }
                        SettingRow { label: "Bottom"; rowOpacity: extraGapsToggle.checked ? 1 : 0.5
                            NumberField {
                                value: Config.niriInfo && Config.niriInfo["struts"] ? Config.niriInfo["struts"]["bottom"] : "0"
                                suffix: "px"; enabled: extraGapsToggle.checked
                                onValueChanged: Config.niriInfo["struts"]["bottom"] = value;
                            }
                        }
                        SettingRow { label: "Left";   rowOpacity: extraGapsToggle.checked ? 1 : 0.5
                            NumberField {
                                value: Config.niriInfo && Config.niriInfo["struts"] ? Config.niriInfo["struts"]["left"] : "0"
                                suffix: "px"; enabled: extraGapsToggle.checked
                                onValueChanged: Config.niriInfo["struts"]["left"] = value;
                            }
                        }
                        SettingRow { label: "Right";  rowOpacity: extraGapsToggle.checked ? 1 : 0.5; showSeparator: false
                            NumberField {
                                value: Config.niriInfo && Config.niriInfo["struts"] ? Config.niriInfo["struts"]["right"] : "0"
                                suffix: "px"; enabled: extraGapsToggle.checked
                                onValueChanged: Config.niriInfo["struts"]["right"] = value;
                            }
                        }
                    }

                    Item { Layout.fillHeight: true; }
                }
            }
        }
    }

    // ═══════════════════════════════════════════════════════════════════
    // WALLPAPER PANEL
    // ═══════════════════════════════════════════════════════════════════

    component WallpaperPanel: Rectangle {
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
                    text: "Wallpaper"
                    color: Config.text
                    font.pixelSize: Config.scFont(18)
                    font.bold: true
                    font.family: Config.fontFamily
                }

                Item { Layout.fillWidth: true; }

                ActionButton {
                    text: "Apply"
                    Layout.preferredWidth: Config.sc(60)
                    Layout.preferredHeight: Config.sc(32)
                    onClicked: {
                        if (configPanel.selectedWallpaperIndex >= 0 && configPanel.selectedWallpaperIndex < configPanel.wallPaperModel.length)
                            Buttoncommand.changeWallpaper(configPanel.wallPaperModel[configPanel.selectedWallpaperIndex].path);
                    }
                }

                CloseButton { onClicked: Config.configPanelVisible = false; }
            }

            // Scrollable content
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
                ScrollBar.vertical: ScrollBar { policy: ScrollBar.AsNeeded; }

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
                                required property int index
                                required property var modelData

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

    // ═══════════════════════════════════════════════════════════════════
    // BLUETOOTH PANEL
    // ═══════════════════════════════════════════════════════════════════

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

                Item { Layout.fillWidth: true; }

                CloseButton { onClicked: Config.configPanelVisible = false; }
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
                ScrollBar.vertical: ScrollBar { policy: ScrollBar.AsNeeded; }

                ColumnLayout {
                    id: bluetoothColumn
                    width: parent.width - Config.sc(17)
                    anchors.left: parent.left
                    spacing: Config.sc(20)

                    // Toggle
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
                            anchors.right: parent.right
                            anchors.rightMargin: Config.sc(20)
                            anchors.verticalCenter: parent.verticalCenter
                            checked: bluetoothPanel.bluetoothEnabled
                            onToggled: bluetoothPanel.bluetoothEnabled = !bluetoothPanel.bluetoothEnabled;
                        }
                    }

                    // New Devices
                    Item {
                        Layout.fillWidth: true
                        Layout.preferredHeight: Config.sc(32)
                        visible: bluetoothPanel.bluetoothEnabled

                        Text {
                            text: "New Devices"
                            color: Config.text
                            font.pixelSize: Config.scFont(15)
                            font.family: Config.fontFamily
                            font.bold: true
                            anchors.verticalCenter: parent.verticalCenter
                        }

                        Item {
                            id: btLoadingIcon
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
                                target: btLoadingIcon
                                from: 0; to: 360
                                duration: 1000
                                loops: Animation.Infinite
                                running: configPanel.currentPanel === 2
                            }
                        }
                    }

                    Rectangle {
                        Layout.fillWidth: true
                        Layout.preferredHeight: Math.max(btDeviceList.count * Config.sc(60), Config.sc(60))
                        color: Config.foreground
                        radius: Config.sc(15)
                        visible: bluetoothPanel.bluetoothEnabled

                        Text {
                            text: "Searching for devices..."
                            font.pixelSize: Config.scFont(15)
                            font.family: Config.fontFamily
                            color: Config.text
                            anchors.centerIn: parent
                            visible: btDeviceList.count === 0
                        }

                        ListView {
                            id: btDeviceList
                            model: configPanel.bluetoothModel
                            anchors.fill: parent
                            spacing: 0
                            visible: btDeviceList.count > 0

                            delegate: Item {
                                id: btDelegate
                                required property var modelData
                                required property int index

                                width: parent.width
                                height: Config.sc(60)

                                RowLayout {
                                    anchors.fill: parent
                                    anchors.leftMargin: Config.sc(20)
                                    anchors.rightMargin: Config.sc(20)

                                    Text {
                                        text: modelData.name
                                        font.pixelSize: Config.scFont(15)
                                        font.family: Config.fontFamily
                                        color: Config.text
                                        Layout.fillWidth: true
                                    }

                                    ActionButton {
                                        text: "Connect"
                                        Layout.preferredWidth: Config.sc(90)
                                        Layout.preferredHeight: Config.sc(40)
                                        onClicked: {
                                            Buttoncommand.bluetoothConnect(modelData.address);
                                            refreshBluetoothTimer.start();
                                        }
                                    }
                                }

                                Rectangle {
                                    visible: index < btDeviceList.count - 1
                                    anchors.bottom: parent.bottom
                                    width: parent.width
                                    height: 1
                                    color: Config.progressColor
                                }
                            }
                        }
                    }

                    // Connected Devices
                    Item {
                        Layout.fillWidth: true
                        Layout.preferredHeight: Config.sc(32)
                        visible: bluetoothPanel.bluetoothEnabled

                        Text {
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
                        Layout.preferredHeight: btConnectedList.count * Config.sc(60)
                        color: Config.foreground
                        radius: Config.sc(15)
                        visible: bluetoothPanel.bluetoothEnabled

                        ListView {
                            id: btConnectedList
                            model: configPanel.connectedModel
                            anchors.fill: parent
                            spacing: 0

                            delegate: Item {
                                id: btConnectedDelegate
                                required property var modelData
                                required property int index

                                width: parent.width
                                height: Config.sc(60)

                                RowLayout {
                                    anchors.fill: parent
                                    anchors.leftMargin: Config.sc(20)
                                    anchors.rightMargin: Config.sc(20)

                                    Text {
                                        text: modelData.name
                                        font.pixelSize: Config.scFont(15)
                                        font.family: Config.fontFamily
                                        color: Config.text
                                        Layout.fillWidth: true
                                    }

                                    ActionButton {
                                        text: "Delete"
                                        btnColor: Config.closeColor
                                        normalOpacity: 0.6
                                        Layout.preferredWidth: Config.sc(90)
                                        Layout.preferredHeight: Config.sc(40)
                                        onClicked: {
                                            Buttoncommand.bluetoothDisconnect(modelData.address);
                                            refreshConnectedTimer.start();
                                        }
                                    }
                                }

                                Rectangle {
                                    visible: index < btConnectedList.count - 1
                                    anchors.bottom: parent.bottom
                                    width: parent.width
                                    height: 1
                                    color: Config.progressColor
                                }
                            }
                        }
                    }

                    Item { Layout.fillHeight: true; }
                }
            }
        }
    }

    // ═══════════════════════════════════════════════════════════════════
    // WIFI PANEL
    // ═══════════════════════════════════════════════════════════════════

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

                Item { Layout.fillWidth: true; }

                CloseButton { onClicked: Config.configPanelVisible = false; }
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
                ScrollBar.vertical: ScrollBar { policy: ScrollBar.AsNeeded; }

                ColumnLayout {
                    id: wifiColumn
                    width: parent.width - Config.sc(17)
                    anchors.left: parent.left
                    spacing: Config.sc(20)

                    // Toggle
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
                            anchors.right: parent.right
                            anchors.rightMargin: Config.sc(20)
                            anchors.verticalCenter: parent.verticalCenter
                            checked: wifiPanel.wifiEnabled
                            onToggled: wifiPanel.wifiEnabled = !wifiPanel.wifiEnabled;
                        }
                    }

                    // Connected
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
                            spacing: 0

                            delegate: Item {
                                id: wifiConnectedDelegate
                                required property var modelData
                                required property int index

                                width: parent.width
                                height: Config.sc(60)

                                RowLayout {
                                    anchors.fill: parent
                                    anchors.leftMargin: Config.sc(20)
                                    anchors.rightMargin: Config.sc(20)
                                    spacing: Config.sc(12)

                                    Text {
                                        text: "\uf1eb"
                                        font.pixelSize: Config.scFont(18)
                                        font.family: Config.fontFamily
                                        color: Config.text
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

                                    ActionButton {
                                        text: "Disconnect"
                                        btnColor: Config.closeColor
                                        normalOpacity: 0.6
                                        Layout.preferredWidth: Config.sc(90)
                                        Layout.preferredHeight: Config.sc(40)
                                        onClicked: Buttoncommand.wifiDisconnect(modelData.name);
                                    }
                                }

                                Rectangle {
                                    visible: index < wifiConnectedList.count - 1
                                    anchors.bottom: parent.bottom
                                    width: parent.width
                                    height: 1
                                    color: Config.progressColor
                                }
                            }
                        }
                    }

                    // Available Networks
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
                                from: 0; to: 360
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
                            spacing: 0
                            visible: wifiScanList.count > 0

                            delegate: Item {
                                id: wifiScanDelegate
                                required property var modelData
                                required property int index

                                width: parent.width
                                height: Config.sc(60)

                                RowLayout {
                                    anchors.fill: parent
                                    anchors.leftMargin: Config.sc(20)
                                    anchors.rightMargin: Config.sc(20)
                                    spacing: Config.sc(12)

                                    // Signal icon with opacity for strength
                                    Text {
                                        text: "\uf1eb"
                                        font.pixelSize: Config.scFont(18)
                                        font.family: Config.fontFamily
                                        color: Config.text
                                        opacity: {
                                            let s = parseInt(modelData.signal);
                                            return s >= 80 ? 1 : s >= 60 ? 0.8 : s >= 40 ? 0.6 : 0.4;
                                        }
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

                                    Text {
                                        text: (modelData.signal || "0") + "%"
                                        font.pixelSize: Config.scFont(13)
                                        font.family: Config.fontFamily
                                        color: Config.text
                                        opacity: 0.6
                                    }

                                    ActionButton {
                                        text: "Connect"
                                        Layout.preferredWidth: Config.sc(90)
                                        Layout.preferredHeight: Config.sc(40)
                                        onClicked: {
                                            Config.selectedWifi = { name: modelData.name, signal: modelData.signal, security: modelData.security };
                                            Config.wifiPasswordPopupVisible = true;
                                        }
                                    }
                                }

                                Rectangle {
                                    visible: index < wifiScanList.count - 1
                                    anchors.bottom: parent.bottom
                                    width: parent.width
                                    height: 1
                                    color: Config.progressColor
                                }
                            }
                        }
                    }

                    Item { Layout.fillHeight: true; }
                }
            }
        }
    }

    // ═══════════════════════════════════════════════════════════════════
    // MODE SELECTOR (for Display panel)
    // ═══════════════════════════════════════════════════════════════════

    component ModeSelector: Item {
        id: modeSelector
        property var modes: []
        property string currentMode: ""
        property bool expanded: false
        signal modeSelected(string mode)

        width: Config.sc(160)
        height: Config.sc(32)

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
                onClicked: expanded ? dropdownPopup.close() : dropdownPopup.open()
            }
        }

        Popup {
            id: dropdownPopup
            x: 0
            y: modeSelector.height + Config.sc(2)
            width: modeSelector.width
            height: Config.sc(32) * 4
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
                ScrollBar.vertical: ScrollBar { policy: ScrollBar.AsNeeded; }

                Column {
                    id: modeListColumn
                    width: parent.width
                    spacing: 0

                    Repeater {
                        model: modeSelector.modes

                        Rectangle {
                            required property string modelData

                            width: dropdownPopup.width - Config.sc(4)
                            height: Config.sc(32)
                            color: modeItemMouseArea.containsMouse ? Config.textselect : "transparent"
                            radius: Config.sc(4)
                            Behavior on color { ColorAnimation { duration: 200; easing.type: Easing.InOutQuad; } }

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

    // ═══════════════════════════════════════════════════════════════════
    // DISPLAY PANEL
    // ═══════════════════════════════════════════════════════════════════

    component DisplayPanel: Rectangle {
        id: displayPanel
        color: Config.background
        topRightRadius: Config.sc(35)
        bottomRightRadius: Config.sc(35)

        property var setMonitor: []
        property string setPriScreen: ""

        function isPrimary(name) {
            let target = displayPanel.setPriScreen !== "" ? displayPanel.setPriScreen : Config.priScreen;
            return name === target;
        }

        Component.onCompleted: {
            let info = [];
            for (let i = 0; i < configPanel.monitors.length; i++) {
                info.push({ name: configPanel.monitors[i].name, currentMode: configPanel.monitors[i].currentMode, scale: configPanel.monitors[i].scale });
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

                Item { Layout.fillWidth: true; }

                ActionButton {
                    text: "Apply"
                    Layout.preferredWidth: Config.sc(60)
                    Layout.preferredHeight: Config.sc(32)
                    onClicked: {
                        if (displayPanel.setMonitor.length > 0)
                            Buttoncommand.setMonitorExec(displayPanel.setMonitor);
                        if (displayPanel.setPriScreen !== "") {
                            let w = "", h = "";
                            for (let i = 0; i < displayPanel.setMonitor.length; i++) {
                                if (displayPanel.setMonitor[i].name === displayPanel.setPriScreen) {
                                    let m = displayPanel.setMonitor[i].currentMode.match(/(\d+)x(\d+)/);
                                    if (m) { w = parseInt(m[1]); h = parseInt(m[2]); break; }
                                }
                            }
                            Config.screenWidth = w;
                            Config.screenHeight = h;
                            Config.priScreen = displayPanel.setPriScreen;
                        }
                    }
                }

                CloseButton { onClicked: Config.configPanelVisible = false; }
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
                ScrollBar.vertical: ScrollBar { policy: ScrollBar.AsNeeded; }

                ColumnLayout {
                    id: displayColumn
                    width: parent.width - Config.sc(17)
                    anchors.left: parent.left
                    spacing: Config.sc(20)

                    Repeater {
                        model: configPanel.monitors

                        ColumnLayout {
                            required property var modelData

                            Layout.fillWidth: true
                            spacing: Config.sc(10)

                            // Monitor name header
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
                                    text: "Primary"
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

                                    SettingRow { label: "Mode"
                                        ModeSelector {
                                            modes: modelData.modes
                                            currentMode: modelData.currentMode
                                            onModeSelected: function(mode) {
                                                for (let i = 0; i < displayPanel.setMonitor.length; i++) {
                                                    if (displayPanel.setMonitor[i].name === modelData.name) {
                                                        displayPanel.setMonitor[i].currentMode = mode;
                                                        break;
                                                    }
                                                }
                                            }
                                        }
                                    }

                                    SettingRow { label: "Scale"
                                        NumberField {
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

                                    SettingRow { label: "Set Primary Monitor"
                                        ToggleSwitch {
                                            bindable: true
                                            checked: displayPanel.isPrimary(modelData.name)
                                            onToggled: displayPanel.setPriScreen = modelData.name;
                                        }
                                    }
                                }
                            }
                        }
                    }

                    Item { Layout.fillHeight: true; }
                }
            }
        }
    }
}
