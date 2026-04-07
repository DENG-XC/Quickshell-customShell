import QtQuick
import QtQuick.Layouts
import QtQuick.Controls
import Quickshell
import Quickshell.Io
import Quickshell.Wayland
import Qt5Compat.GraphicalEffects
import "../js/UpdateFilter.js" as UpdateFilter
import "../js/LaunchSelectedApp.js" as LaunchSelectedApp

FloatingWindow {
    id: clipboardPopup
    title: "clipboard"
    screen: {
        for (let i = 0; i < Quickshell.screens.length; i++) {
            if (Quickshell.screens[i].name === Config.priScreen) {
                return Quickshell.screens[i];
            }
        }
        return Quickshell.screens[0];
    }
    maximumSize: Qt.size(Config.sc(800), Config.sc(530))
    color: "transparent"

    property var clipboardModel: []
    property var fullData: []
    property var previewItem: null
    property string filterMode: "all"
    property bool searchMode: true
    property bool normalMode: false

    onVisibleChanged: {
        if (!visible) {
            Config.clipboardVisible = false;
        }
    }

    Process {
        id: clipboardList
        command: ["bash", "-c", "cat ~/.config/clipse/clipboard_history.json"]
        running: false
        stdout: StdioCollector {
            onStreamFinished: clipboardPopup.clipboardHistory(this.text)
        }
    }

    Process {
        id: actionProcess
        command: []
        running: false
        onRunningChanged: {
            if (!running) {
                clipboardPopup.refreshData();
            }
        }
    }

    Process {
        id: copyProcess
        command: []
        running: false
        onRunningChanged: {
            if (!running) {
                refreshTimer.start();
            }
        }
    }

    Timer {
        id: refreshTimer
        interval: 250
        running: false
        onTriggered: {
            clipboardPopup.refreshData();
        }
    }

    function refreshData() {
        clipboardList.running = false;
        clipboardList.running = true;
    }

    function deleteItem(recordedTime) {
        actionProcess.command = ["python3", Config.shellDir + "/scripts/clipManager.py", "delete", recordedTime];
        actionProcess.running = true;
    }

    function pinItem(recordedTime) {
        actionProcess.command = ["python3", Config.shellDir + "/scripts/clipManager.py", "pin", recordedTime];
        actionProcess.running = true;
    }

    function copyItem(content) {
        if (!content) {
            console.error("Content is empty");
            return;
        }

        if (content.filePath === "null") {
            copyProcess.command = ["wl-copy", content.value];
        } else {
            copyProcess.command = ["bash", "-c", `wl-copy <${content.filePath}`];
        }
        copyProcess.running = true;
    }

    function clipboardHistory(text) {
        if (!text)
            return;

        try {
            const rawHistory = JSON.parse(text);

            const cleanHistory = rawHistory.clipboardHistory.filter(item => {
                const value = item.value;
                if (value.startsWith("<meta http")) {
                    return false;
                }
                return true;
            });

            clipboardPopup.fullData = cleanHistory;
            clipboardPopup.updateView();
        } catch (error) {
            console.error("Error parsing clipboard history:", error);
        }
    }

    function updateView() {
        if (clipboardPopup.filterMode === "all") {
            clipboardPopup.clipboardModel = clipboardPopup.fullData;
        } else if (clipboardPopup.filterMode === "images") {
            clipboardPopup.clipboardModel = clipboardPopup.fullData.filter(item => item.filePath !== "null");
        } else if (clipboardPopup.filterMode === "text") {
            clipboardPopup.clipboardModel = clipboardPopup.fullData.filter(item => item.filePath === "null");
        } else if (clipboardPopup.filterMode === "pinned") {
            clipboardPopup.clipboardModel = clipboardPopup.fullData.filter(item => item.pinned === true);
        }

        if (contentLoader.item) {
            Config.currentClipboardIndex = 0;
        }
    }

    function fuzzySearch(text, item) {
        let input = text.toLowerCase();
        let fullData = item.value.toLowerCase();

        let searchIndex = 0;

        for (let i = 0; i < fullData.length; i++) {
            let currentLetter = fullData[i];
            let targetLetter = input[searchIndex];

            if (currentLetter === targetLetter) {
                searchIndex++;
            }

            if (searchIndex === input.length) {
                return true;
            }
        }

        return false;
    }

    function filterSearch(text) {
        if (text === "") {
            clipboardPopup.updateView();
            return;
        }

        let sourceData = [];

        if (clipboardPopup.filterMode === "all") {
            sourceData = clipboardPopup.fullData;
        } else if (clipboardPopup.filterMode === "images") {
            sourceData = clipboardPopup.fullData.filter(item => item.filePath !== "null");
        } else if (clipboardPopup.filterMode === "text") {
            sourceData = clipboardPopup.fullData.filter(item => item.filePath === "null");
        } else if (clipboardPopup.filterMode === "pinned") {
            sourceData = clipboardPopup.fullData.filter(item => item.pinned === true);
        }

        clipboardPopup.clipboardModel = sourceData.filter(item => fuzzySearch(text, item));

        if (contentLoader.item) {
            Config.currentClipboardIndex = 0;
        }
    }

    Component.onCompleted: {
        clipboardPopup.refreshData();
    }

    ListModel {
        id: filterButtons
        ListElement {
            label: ""
            mode: "all"
        }
        ListElement {
            label: ""
            mode: "images"
        }
        ListElement {
            label: ""
            mode: "text"
        }
        ListElement {
            label: ""
            mode: "pinned"
        }
    }

    Rectangle {
        id: clipboardContainer
        anchors.centerIn: parent
        color: Config.background
        radius: Config.sc(35)
        width: Config.sc(800)
        height: Config.sc(530)
        focus: clipboardPopup.normalMode
        Keys.onPressed: function (event) {
            if (event.key === Qt.Key_Q) {
                Config.clipboardVisible = false;
                Config.currentAppIndex = 0;
            } else if (event.key === Qt.Key_Slash) {
                clipboardPopup.normalMode = false;
                clipboardPopup.searchMode = true;
            } else if (event.key === Qt.Key_Tab) {
                event.accepted = true;
            } else if (event.key === Qt.Key_J || event.key === Qt.Key_Down) {
                if (Config.currentClipboardIndex < clipboardPopup.clipboardModel.length - 1) {
                    Config.currentClipboardIndex++;
                }
            } else if (event.key === Qt.Key_K || event.key === Qt.Key_Up) {
                if (Config.currentClipboardIndex > 0) {
                    Config.currentClipboardIndex--;
                }
            } else if (event.key === Qt.Key_D) {
                if (contentLoader.status === Loader.Ready && contentLoader.item) {
                    let currentItem = contentLoader.item.listView.currentItem;
                    if (currentItem) {
                        currentItem.triggerDelete();
                    }
                }
            } else if (event.key === Qt.Key_Y) {
                if (Config.currentClipboardIndex >= 0 && Config.currentClipboardIndex < clipboardPopup.clipboardModel.length) {
                    if (contentLoader.status === Loader.Ready && contentLoader.item) {
                        let currentItem = contentLoader.item.listView.currentItem;
                        if (currentItem) {
                            currentItem.isCopied = true;
                            clipboardPopup.copyItem(clipboardPopup.clipboardModel[Config.currentClipboardIndex]);
                        }
                    }
                }
            } else if (event.key === Qt.Key_H || event.key === Qt.Key_Left) {
                if (clipboardPopup.filterMode === "images") {
                    clipboardPopup.filterMode = "all";
                    clipboardPopup.updateView();
                } else if (clipboardPopup.filterMode === "text") {
                    clipboardPopup.filterMode = "images";
                    clipboardPopup.updateView();
                } else if (clipboardPopup.filterMode === "pinned") {
                    clipboardPopup.filterMode = "text";
                    clipboardPopup.updateView();
                }
            } else if (event.key === Qt.Key_L || event.key === Qt.Key_Right) {
                if (clipboardPopup.filterMode === "images") {
                    clipboardPopup.filterMode = "text";
                    clipboardPopup.updateView();
                } else if (clipboardPopup.filterMode === "all") {
                    clipboardPopup.filterMode = "images";
                    clipboardPopup.updateView();
                } else if (clipboardPopup.filterMode === "text") {
                    clipboardPopup.filterMode = "pinned";
                    clipboardPopup.updateView();
                }
            } else if (event.key === Qt.Key_P) {
                if (Config.currentClipboardIndex >= 0 && Config.currentClipboardIndex < clipboardPopup.clipboardModel.length) {
                    clipboardPopup.pinItem(clipboardPopup.clipboardModel[Config.currentClipboardIndex].recorded);
                }
            }
        }

        ColumnLayout {
            id: columnLayout
            anchors.fill: parent
            spacing: Config.sc(20)

            Item {
                id: topPanel
                Layout.fillWidth: true
                Layout.preferredHeight: Config.sc(50)
                Layout.rightMargin: Config.sc(Config.gaps)
                Layout.leftMargin: Config.sc(Config.gaps)
                Layout.topMargin: Config.sc(Config.gaps)

                Rectangle {
                    id: textFieldBackground
                    color: Config.foreground
                    radius: height / 2
                    height: parent.height
                    anchors.left: parent.left
                    anchors.right: closeButton.left
                    anchors.rightMargin: Config.sc(Config.gaps)
                }

                Text {
                    id: searchIcon
                    text: ""
                    color: Config.text
                    font.pixelSize: Config.scFont(16)
                    font.bold: true
                    font.family: Config.fontFamily
                    z: 1
                    anchors.verticalCenter: parent.verticalCenter
                    anchors.leftMargin: Config.sc(Config.gaps)
                    anchors.left: textFieldBackground.left
                }

                TextField {
                    id: searchText
                    background: Rectangle {
                        color: "transparent"
                    }
                    placeholderText: "Search"
                    placeholderTextColor: Config.text
                    height: parent.height
                    color: Config.text
                    focus: clipboardPopup.searchMode
                    font.pixelSize: Config.scFont(16)
                    font.bold: true
                    font.family: Config.fontFamily
                    anchors.left: searchIcon.right
                    anchors.leftMargin: Config.sc(Config.gaps)
                    anchors.right: closeButton.left
                    anchors.rightMargin: Config.sc(Config.gaps)

                    Keys.onPressed: function (event) {
                        if (event.key === Qt.Key_Escape) {
                            clipboardPopup.searchMode = false;
                            clipboardPopup.normalMode = true;
                            clipboardContainer.forceActiveFocus();
                            event.accepted = true;
                        } else if (event.key === Qt.Key_Tab) {
                            event.accepted = true;
                        }
                    }

                    onTextChanged: {
                        clipboardPopup.filterSearch(text);
                    }

                    onPressed: {
                        clipboardPopup.searchMode = true;
                        clipboardPopup.normalMode = false;
                    }
                }

                Item {
                    id: closeButton
                    width: Config.sc(50)
                    height: Config.sc(50)
                    anchors.right: parent.right

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
                        id: closeButtonIcon
                        anchors.centerIn: parent
                        text: ""
                        font.pixelSize: Config.scFont(28)
                        font.bold: false
                        font.family: Config.fontFamily
                        color: Config.text
                        opacity: 1
                    }

                    MouseArea {
                        anchors.fill: parent
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
                        onEntered: parent.isHovered = true
                        onExited: parent.isHovered = false
                        onClicked: {
                            Config.clipboardVisible = false;
                            Config.currentAppIndex = 0;
                        }
                    }
                }
            }

            Item {
                id: widgetLoaderContainer
                Layout.fillHeight: true
                Layout.fillWidth: true

                Component {
                    id: clipboardComponent

                    Item {
                        id: clipComponent

                        property alias listView: clipboardListView

                        Rectangle {
                            id: previewContainer
                            width: parent.width / 2 - Config.sc(30)
                            anchors.left: parent.left
                            anchors.leftMargin: Config.sc(Config.gaps)
                            anchors.top: rowLayoutButtons.bottom
                            anchors.topMargin: Config.sc(Config.gaps)
                            anchors.bottom: parent.bottom
                            anchors.bottomMargin: Config.sc(Config.gaps)
                            color: Config.foreground
                            radius: Config.sc(25)

                            Component {
                                id: imageComponent
                                Image {
                                    id: image
                                    source: clipboardPopup.previewItem.filePath
                                    fillMode: Image.PreserveAspectFit
                                    asynchronous: true
                                }
                            }

                            Component {
                                id: textComponent
                                ScrollView {
                                    TextArea {
                                        text: clipboardPopup.previewItem.value
                                        font.family: Config.fontFamily
                                        font.pixelSize: Config.scFont(16)
                                        font.bold: true
                                        color: Config.text
                                        wrapMode: Text.Wrap
                                        readOnly: true
                                        background: null
                                    }
                                }
                            }

                            Loader {
                                anchors.fill: parent
                                anchors.margins: Config.sc(Config.gaps)
                                sourceComponent: {
                                    if (!clipboardPopup.previewItem) {
                                        return null;
                                    } else if (clipboardPopup.previewItem.filePath === "null") {
                                        return textComponent;
                                    } else {
                                        return imageComponent;
                                    }
                                }
                            }
                        }

                        ListView {
                            id: clipboardListView
                            height: parent.height - Config.sc(20)
                            width: parent.width / 2 - Config.sc(30)
                            anchors.right: parent.right
                            anchors.rightMargin: Config.sc(Config.gaps)
                            model: clipboardPopup.clipboardModel
                            spacing: Config.sc(20)
                            clip: true
                            currentIndex: Config.currentClipboardIndex

                            property int listHeight: (height - Config.sc(80)) / 5

                            onCurrentIndexChanged: {
                                if (currentIndex >= 0 && currentIndex < clipboardPopup.clipboardModel.length) {
                                    clipboardPopup.previewItem = clipboardPopup.clipboardModel[currentIndex];
                                }
                            }

                            delegate: Item {
                                id: delegateItem
                                width: clipboardListView.width
                                height: clipboardListView.listHeight

                                function triggerDelete() {
                                    if (!removeAnimation.running) {
                                        removeAnimation.start();
                                    }
                                }

                                SequentialAnimation {
                                    id: removeAnimation
                                    running: false

                                    ParallelAnimation {
                                        NumberAnimation {
                                            target: delegateItem
                                            property: "opacity"
                                            to: 0
                                            duration: 200
                                            easing.type: Easing.InOutQuad
                                        }

                                        NumberAnimation {
                                            target: delegateItem
                                            property: "x"
                                            to: delegateItem.width
                                            duration: 200
                                            easing.type: Easing.InOutQuad
                                        }
                                    }

                                    NumberAnimation {
                                        target: delegateItem
                                        property: "height"
                                        to: 0
                                        duration: 200
                                        easing.type: Easing.InOutQuad
                                    }

                                    ScriptAction {
                                        script: clipboardPopup.deleteItem(modelData.recorded)
                                    }
                                }

                                property bool isHovered: false
                                property bool isCopied: false
                                readonly property bool isSelected: ListView.isCurrentItem

                                MouseArea {
                                    anchors.fill: parent
                                    hoverEnabled: true
                                    cursorShape: Qt.PointingHandCursor
                                    onEntered: {
                                        isHovered = true;
                                    }
                                    onExited: {
                                        isHovered = false;
                                    }
                                    onClicked: {
                                        Config.currentClipboardIndex = index;
                                        clipboardPopup.previewItem = modelData;
                                    }

                                    Rectangle {
                                        width: parent.width
                                        height: parent.height
                                        color: isSelected ? Config.textHover : isHovered ? Config.textselect : "transparent"
                                        radius: Config.sc(25)
                                        opacity: 1

                                        Behavior on opacity {
                                            NumberAnimation {
                                                duration: 200
                                                easing.type: Easing.InOutQuad
                                            }
                                        }
                                    }

                                    Text {
                                        anchors.leftMargin: Config.sc(80)
                                        anchors.left: parent.left
                                        anchors.top: listIcon.top
                                        text: (modelData.filePath === "null") ? "Text" : "Image"
                                        font.pixelSize: Config.scFont(16)
                                        font.bold: true
                                        font.family: Config.fontFamily
                                        color: Config.text
                                    }

                                    Image {
                                        id: listIcon
                                        source: (modelData.filePath === "null") ? "../logo/text.svg" : "../logo/image.svg"
                                        anchors.left: parent.left
                                        anchors.leftMargin: Config.sc(Config.gaps)
                                        anchors.verticalCenter: parent.verticalCenter
                                        width: Config.sc(45)
                                        height: Config.sc(45)
                                        sourceSize.height: Config.sc(45)
                                        sourceSize.width: Config.sc(45)
                                        fillMode: Image.PreserveAspectFit
                                    }

                                    Text {
                                        id: listTime
                                        anchors.bottom: listIcon.bottom
                                        anchors.left: parent.left
                                        anchors.leftMargin: Config.sc(80)
                                        text: modelData.recorded.split(".")[0]
                                        font.pixelSize: Config.scFont(12)
                                        font.bold: false
                                        font.family: Config.fontFamily
                                        color: Config.text
                                        opacity: 0.6
                                    }

                                    Rectangle {
                                        id: closeRect
                                        anchors.right: parent.right
                                        anchors.rightMargin: Config.sc(Config.gaps)
                                        anchors.verticalCenter: parent.verticalCenter
                                        width: Config.sc(24)
                                        height: Config.sc(24)
                                        color: Config.closeColor
                                        radius: Config.sc(12)
                                        opacity: closeMouseArea.containsMouse ? 1 : 0.6

                                        Behavior on opacity {
                                            NumberAnimation {
                                                duration: 200
                                                easing.type: Easing.InOutQuad
                                            }
                                        }

                                        Text {
                                            anchors.centerIn: parent
                                            text: ""
                                            font.pixelSize: Config.scFont(14)
                                            font.bold: true
                                            font.family: Config.fontFamily
                                            color: Config.background
                                        }

                                        MouseArea {
                                            id: closeMouseArea
                                            anchors.fill: parent
                                            hoverEnabled: true
                                            cursorShape: Qt.PointingHandCursor

                                            onClicked: {
                                                delegateItem.triggerDelete();
                                            }
                                        }
                                    }

                                    Rectangle {
                                        id: copyRect
                                        anchors.right: closeRect.left
                                        anchors.rightMargin: Config.sc(Config.gaps)
                                        anchors.verticalCenter: parent.verticalCenter
                                        width: Config.sc(24)
                                        height: Config.sc(24)
                                        color: Config.expandedColor
                                        radius: Config.sc(12)
                                        opacity: copyMouseArea.containsMouse ? 1 : delegateItem.isCopied ? 1 : 0.6

                                        Behavior on opacity {
                                            NumberAnimation {
                                                duration: 200
                                                easing.type: Easing.InOutQuad
                                            }
                                        }

                                        Text {
                                            anchors.centerIn: parent
                                            text: delegateItem.isCopied ? "" : ""
                                            font.pixelSize: Config.scFont(14)
                                            font.bold: true
                                            font.family: Config.fontFamily
                                            color: Config.background
                                        }

                                        MouseArea {
                                            id: copyMouseArea
                                            anchors.fill: parent
                                            hoverEnabled: true
                                            cursorShape: Qt.PointingHandCursor

                                            onClicked: {
                                                if (Config.currentClipboardIndex >= 0 && Config.currentClipboardIndex < clipboardPopup.clipboardModel.length) {
                                                    clipboardPopup.copyItem(clipboardPopup.clipboardModel[Config.currentClipboardIndex]);
                                                    delegateItem.isCopied = true;
                                                }
                                            }
                                        }
                                    }

                                    Rectangle {
                                        id: pinRect
                                        anchors.right: copyRect.left
                                        anchors.rightMargin: Config.sc(Config.gaps)
                                        anchors.verticalCenter: parent.verticalCenter
                                        width: Config.sc(24)
                                        height: Config.sc(24)
                                        color: Config.pinColor
                                        radius: Config.sc(12)
                                        opacity: pinMouseArea.containsMouse ? 1 : modelData.pinned ? 1 : 0.6

                                        Behavior on opacity {
                                            NumberAnimation {
                                                duration: 200
                                                easing.type: Easing.InOutQuad
                                            }
                                        }

                                        Text {
                                            anchors.centerIn: parent
                                            text: ""
                                            font.pixelSize: Config.scFont(14)
                                            font.bold: true
                                            font.family: Config.fontFamily
                                            color: Config.background
                                        }

                                        MouseArea {
                                            id: pinMouseArea
                                            anchors.fill: parent
                                            hoverEnabled: true
                                            cursorShape: Qt.PointingHandCursor

                                            onClicked: {
                                                clipboardPopup.pinItem(modelData.recorded);
                                            }
                                        }
                                    }
                                }
                            }
                        }
                        RowLayout {
                            id: rowLayoutButtons
                            width: parent.width / 2 - Config.sc(30)
                            height: clipboardListView.listHeight
                            anchors.left: parent.left
                            anchors.leftMargin: Config.sc(Config.gaps)
                            spacing: 0

                            Repeater {
                                model: filterButtons
                                delegate: Item {
                                    id: delegateItem
                                    Layout.fillWidth: true
                                    Layout.fillHeight: true

                                    property bool isHovered: false

                                    Item {
                                        anchors.fill: parent
                                        opacity: 1

                                        Text {
                                            id: buttonIcon
                                            text: label
                                            anchors.centerIn: parent
                                            font.pixelSize: Config.scFont(20)
                                            font.bold: true
                                            font.family: Config.fontFamily
                                            color: Config.text
                                            opacity: clipboardPopup.filterMode === mode ? 1 : (delegateItem.isHovered ? 1 : 0.6)

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
                                                    clipboardPopup.filterMode = mode;
                                                    clipboardPopup.updateView();
                                                }
                                                onEntered: {
                                                    delegateItem.isHovered = true;
                                                }
                                                onExited: {
                                                    delegateItem.isHovered = false;
                                                }
                                            }
                                        }

                                        Rectangle {
                                            id: indicator
                                            width: clipboardPopup.filterMode === mode ? Config.sc(22) : 0
                                            height: Config.sc(5)
                                            color: Config.text
                                            radius: Config.sc(2.5)
                                            anchors.top: buttonIcon.bottom
                                            anchors.topMargin: Config.sc(5)
                                            anchors.horizontalCenter: buttonIcon.horizontalCenter

                                            Behavior on width {
                                                NumberAnimation {
                                                    duration: 200
                                                    easing.type: Easing.InOutQuad
                                                }
                                            }
                                        }
                                    }
                                }
                            }
                        }
                        Rectangle {
                            id: buttonsBackground
                            anchors.fill: rowLayoutButtons
                            color: Config.foreground
                            radius: Config.sc(25)
                            z: -1
                        }
                    }
                }

                Loader {
                    id: contentLoader
                    anchors.fill: parent
                    sourceComponent: clipboardComponent
                }
            }
        }
    }
}
