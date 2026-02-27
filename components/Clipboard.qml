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
    maximumSize: Qt.size(800, 530)
    color: "transparent"

    property var clipboardModel: []
    property var fullData: []
    property var wallPaperModel: []
    property var wallPaperFullData: []
    property var previewItem: null
    property string filterMode: "all"
    property bool searchMode: true
    property bool normalMode: false
    property int selectedWallpaperIndex: 0

    Process {
        id: wallPapersList
        command: ["python3", Config.shellDir + "/scripts/wallPaper.py"]
        running: false
        stdout: StdioCollector {
            onStreamFinished: {
                    let datas = JSON.parse(this.text);
                    clipboardPopup.wallPaperFullData = datas;
                    clipboardPopup.wallPaperModel = datas;
            }
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

        if (Config.toggleClipboard && contentLoader.item) {
            Config.currentClipboardIndex = 0;
        }
    }

    function fuzzySearch(text, item) {
        let input = text.toLowerCase();
        let fullData;

        if (Config.toggleClipboard) {
            fullData = item.value.toLowerCase();
        } else {
            fullData = item.name.toLowerCase();
        }

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

        if (Config.toggleClipboard === true && contentLoader.item) {
            Config.currentClipboardIndex = 0;
        }
    }

    function wallpaperFilter(text) {
        if (text === "") {
            clipboardPopup.wallPaperModel = clipboardPopup.wallPaperFullData;
        } else {
            clipboardPopup.wallPaperModel = clipboardPopup.wallPaperFullData.filter(item => fuzzySearch(text, item));
        }
    }

    Component.onCompleted: {
        clipboardPopup.refreshData();
        wallPapersList.running = true;
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
        radius: 45
        width: 800
        height: 530
        focus: clipboardPopup.normalMode
        Keys.onPressed: function (event) {
            if (event.key === Qt.Key_Q) {
                Config.clipboardVisible = false;
                Config.currentAppIndex = 0;
            } else if (event.key === Qt.Key_Slash) {
                clipboardPopup.normalMode = false;
                clipboardPopup.searchMode = true;
            } else if (event.key === Qt.Key_Tab) {
                Config.toggleClipboard = !Config.toggleClipboard;
                event.accepted = true;
            } else if (event.key === Qt.Key_Return || event.key === Qt.Key_Enter) {
                if (Config.toggleClipboard === false) {
                    Config.clipboardVisible = false;
                    Buttoncommand.changeWallpaper(clipboardPopup.wallPaperModel[clipboardPopup.selectedWallpaperIndex].path)
                    searchText.text = "";
                    event.accepted = true;
                }
            } else if (event.key === Qt.Key_J || event.key === Qt.Key_Down) {
                if (Config.toggleClipboard === false) {
                    let newIndex = clipboardPopup.selectedWallpaperIndex + 3;
                    if (newIndex < clipboardPopup.wallPaperModel.length) {
                        clipboardPopup.selectedWallpaperIndex = newIndex;
                    }
                } else {
                    if (Config.currentClipboardIndex < clipboardPopup.clipboardModel.length - 1) {
                        Config.currentClipboardIndex++;
                    }
                }
            } else if (event.key === Qt.Key_K || event.key === Qt.Key_Up) {
                if (Config.toggleClipboard === false) {
                    let newIndex = clipboardPopup.selectedWallpaperIndex - 3;
                    if (newIndex >= 0) {
                        clipboardPopup.selectedWallpaperIndex = newIndex;
                    }
                } else {
                    if (Config.currentClipboardIndex > 0) {
                        Config.currentClipboardIndex--;
                    }
                }
            } else if (event.key === Qt.Key_D) {
                if (Config.toggleClipboard === true) {
                    if (contentLoader.status === Loader.Ready && contentLoader.item) {
                        let currentItem = contentLoader.item.listView.currentItem;
                        if (currentItem) {
                            currentItem.triggerDelete();
                        }
                    }
                }
            } else if (event.key === Qt.Key_Y) {
                if (Config.toggleClipboard === true) {
                    if (Config.currentClipboardIndex >= 0 && Config.currentClipboardIndex < clipboardPopup.clipboardModel.length) {
                        if (contentLoader.status === Loader.Ready && contentLoader.item) {
                            let currentItem = contentLoader.item.listView.currentItem;
                            if (currentItem) {
                                currentItem.isCopied = true;
                                clipboardPopup.copyItem(clipboardPopup.clipboardModel[Config.currentClipboardIndex]);
                            }
                        }
                    }
                }
            } else if (event.key === Qt.Key_H || event.key === Qt.Key_Left) {
                if (Config.toggleClipboard === true) {
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
                } else {
                    if (clipboardPopup.selectedWallpaperIndex > 0) {
                        clipboardPopup.selectedWallpaperIndex--;
                    }
                }
            } else if (event.key === Qt.Key_L || event.key === Qt.Key_Right) {
                if (Config.toggleClipboard === true) {
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
                } else {
                    if (clipboardPopup.selectedWallpaperIndex < clipboardPopup.wallPaperModel.length - 1) {
                        clipboardPopup.selectedWallpaperIndex++;
                    }
                }
            } else if (event.key === Qt.Key_P) {
                if (Config.toggleClipboard === true) {
                    if (Config.currentClipboardIndex >= 0 && Config.currentClipboardIndex < clipboardPopup.clipboardModel.length) {
                        clipboardPopup.pinItem(clipboardPopup.clipboardModel[Config.currentClipboardIndex].recorded);
                    }
                }
            }
        }

        ColumnLayout {
            id: columnLayout
            anchors.fill: parent
            spacing: 20

            Item {
                id: topPanel
                Layout.fillWidth: true
                Layout.preferredHeight: 50
                Layout.rightMargin: 20
                Layout.leftMargin: 20
                Layout.topMargin: 20

                Rectangle {
                    id: switchContainer
                    width: 200
                    height: 50
                    radius: height / 2
                    color: Config.foreground
                    anchors.top: parent.top
                    anchors.left: parent.left

                    Rectangle {
                        id: switchIndicator
                        width: parent.width * 0.6
                        height: parent.height * 0.8
                        x: Config.toggleClipboard ? parent.width * 0.4 - parent.height * 0.1 : parent.height * 0.1
                        anchors.verticalCenter: parent.verticalCenter
                        color: Config.textHover
                        radius: height / 2

                        Behavior on x {
                            NumberAnimation {
                                duration: 200
                                easing.type: Easing.InOutQuad
                            }
                        }

                        Item {
                            id: textContainer
                            width: parent.width * 0.9
                            height: parent.height * 0.9
                            anchors.centerIn: parent

                            Text {
                                text: Config.toggleClipboard ? "Clipboard" : "Wallpaper"
                                color: Config.text
                                font.pixelSize: 14
                                font.bold: true
                                font.family: Config.fontFamily
                                anchors.centerIn: parent
                            }
                        }
                    }

                    Item {
                        id: appIconIndicator
                        width: parent.width * 0.4
                        height: parent.height * 0.8
                        anchors.left: parent.left
                        anchors.leftMargin: parent.height * 0.1
                        anchors.verticalCenter: parent.verticalCenter
                        visible: Config.toggleClipboard

                        Item {
                            id: appIconContainer
                            width: parent.width * 0.9
                            height: parent.height * 0.9
                            anchors.centerIn: parent

                            Text {
                                text: ""
                                color: Config.text
                                font.pixelSize: 14
                                font.bold: true
                                font.family: Config.fontFamily
                                anchors.centerIn: parent
                            }

                            MouseArea {
                                anchors.fill: parent
                                enabled: Config.toggleClipboard
                                cursorShape: Qt.PointingHandCursor
                                onClicked: {
                                    Config.toggleClipboard = !Config.toggleClipboard;
                                }
                            }
                        }
                    }

                    Item {
                        id: clipIconIndicator
                        width: parent.width * 0.4
                        height: parent.height * 0.8
                        anchors.right: parent.right
                        anchors.rightMargin: parent.height * 0.1
                        anchors.verticalCenter: parent.verticalCenter
                        visible: Config.toggleClipboard ? false : true

                        Item {
                            id: clipIconContainer
                            width: parent.width * 0.9
                            height: parent.height * 0.9
                            anchors.centerIn: parent

                            Text {
                                text: ""
                                color: Config.text
                                font.pixelSize: 14
                                font.bold: true
                                font.family: Config.fontFamily
                                anchors.centerIn: parent
                            }

                            MouseArea {
                                anchors.fill: parent
                                enabled: Config.toggleClipboard ? false : true
                                cursorShape: Qt.PointingHandCursor
                                onClicked: {
                                    Config.toggleClipboard = !Config.toggleClipboard;
                                }
                            }
                        }
                    }
                }

                Rectangle {
                    id: textFieldBackground
                    color: Config.foreground
                    radius: height / 2
                    height: parent.height
                    anchors.left: switchContainer.right
                    anchors.leftMargin: 20
                    anchors.right: closeButton.left
                    anchors.rightMargin: 20
                }

                Text {
                    id: searchIcon
                    text: ""
                    color: Config.text
                    font.pixelSize: 16
                    font.bold: true
                    font.family: Config.fontFamily
                    z: 1
                    anchors.verticalCenter: parent.verticalCenter
                    anchors.leftMargin: 20
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
                    font.pixelSize: 16
                    font.bold: true
                    font.family: Config.fontFamily
                    anchors.left: searchIcon.right
                    anchors.leftMargin: 20
                    anchors.right: closeButton.left
                    anchors.rightMargin: 20

                    Keys.onPressed: function (event) {
                        if (event.key === Qt.Key_Escape) {
                            clipboardPopup.searchMode = false;
                            clipboardPopup.normalMode = true;
                            clipboardContainer.forceActiveFocus();
                            event.accepted = true;
                        } else if (event.key === Qt.Key_Tab) {
                            Config.toggleClipboard = !Config.toggleClipboard;
                            event.accepted = true;
                            if (Config.toggleClipboard === false) {
                                clipboardPopup.searchMode = false;
                                clipboardPopup.normalMode = true;
                                clipboardContainer.forceActiveFocus();
                            }
                        }
                    }

                    onTextChanged: {
                        if (Config.toggleClipboard)
                            clipboardPopup.filterSearch(text);
                        else
                            clipboardPopup.wallpaperFilter(text);
                    }

                    onPressed: {
                        clipboardPopup.searchMode = true;
                        clipboardPopup.normalMode = false;
                    }
                }

                Item {
                    id: closeButton
                    width: 50
                    height: 50
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
                        font.pixelSize: 28
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
                    id: wallPaperComponent

                    ScrollView {
                        id: wallpaperScrollView
                        anchors.fill: parent
                        anchors.bottomMargin: 10
                        anchors.leftMargin: 10
                        anchors.rightMargin: 5
                        clip: true

                        function scrollToSelectedIndex() {
                            let columns = wallpaperGrid.columns;
                            let row = Math.floor(clipboardPopup.selectedWallpaperIndex / columns);
                            let cellHeight = wallpaperGrid.cellHeight;
                            let rowSpacing = wallpaperGrid.rowSpacing;
                            let targetY = row * (cellHeight + rowSpacing);

                            let maxContentY = wallpaperScrollView.contentItem.contentHeight - wallpaperScrollView.height;
                            if (maxContentY < 0) maxContentY = 0;

                            if (targetY < 0) targetY = 0;
                            if (targetY > maxContentY) targetY = maxContentY;

                            wallpaperScrollView.contentItem.contentY = targetY;
                        }

                        Connections {
                            target: clipboardPopup
                            function onSelectedWallpaperIndexChanged() {
                                wallpaperScrollView.scrollToSelectedIndex();
                            }
                        }

                            GridLayout {
                                id: wallpaperGrid
                                x: 15
                                columns: 3
                                columnSpacing: 20
                                rows: 2
                                rowSpacing: 20
                                uniformCellWidths: true
                                uniformCellHeights: true
                                //index: clipboard.selectedWallpaperIndex

                                property int cellWidth: ((wallpaperScrollView.width - 30) - columnSpacing * (columns - 1)) / columns
                                property int cellHeight: ((wallpaperScrollView.height - 10) - rowSpacing * (rows - 1)) / rows

                                Repeater {
                                    model: clipboardPopup.wallPaperModel

                                    delegate: Rectangle {
                                        id: wallpaperCell
                                        Layout.preferredHeight: wallpaperGrid.cellHeight
                                        Layout.preferredWidth: wallpaperGrid.cellWidth

                                        readonly property bool isSelected: index === clipboardPopup.selectedWallpaperIndex
                                        property bool isHovered: false

                                        color: isSelected ? Config.textHover : (isHovered ? Config.textselect : "transparent")
                                        radius: 25

                                        Behavior on color {
                                            ColorAnimation { duration: 200 }
                                        }

                                        Image {
                                            id: wallpaperImage
                                            anchors.top: parent.top
                                            anchors.left: parent.left
                                            anchors.right: parent.right
                                            anchors.bottom: wallpaperName.top
                                            anchors.bottomMargin: 10
                                            anchors.margins: 10
                                            source: modelData.path
                                            fillMode: Image.PreserveAspectCrop
                                            asynchronous: true

                                            layer.enabled: true
                                            layer.effect: OpacityMask {
                                                maskSource: Rectangle {
                                                    width: wallpaperImage.width
                                                    height: wallpaperImage.height
                                                    radius: 15
                                                }
                                            }
                                        }

                                        Text {
                                            id: wallpaperName
                                            anchors.bottom: parent.bottom
                                            anchors.horizontalCenter: parent.horizontalCenter
                                            anchors.bottomMargin: 10
                                            text: modelData.name
                                            color: Config.text
                                            font.pixelSize: 12
                                            font.bold: true
                                            font.family: Config.fontFamily
                                            elide: Text.ElideMiddle
                                            width: parent.width - 20
                                            horizontalAlignment: Text.AlignHCenter
                                        }

                                        MouseArea {
                                            anchors.fill: parent
                                            hoverEnabled: true
                                            cursorShape: Qt.PointingHandCursor
                                            onEntered: wallpaperCell.isHovered = true
                                            onExited: wallpaperCell.isHovered = false
                                            onClicked: {
                                                clipboardPopup.selectedWallpaperIndex = index;
                                                Buttoncommand.changeWallpaper(modelData.path)
                                            }
                                        }
                                    }
                                }
                            }
                    }
                }

                Loader {
                    id: contentLoader
                    anchors.fill: parent
                    sourceComponent: Config.toggleClipboard ? clipboardComponent : wallPaperComponent
                }

                Component {
                    id: clipboardComponent

                    Item {
                        id: clipComponent

                        property alias listView: clipboardListView

                        Rectangle {
                            id: previewContainer
                            width: parent.width / 2 - 30
                            anchors.left: parent.left
                            anchors.leftMargin: 20
                            anchors.top: rowLayoutButtons.bottom
                            anchors.topMargin: 20
                            anchors.bottom: parent.bottom
                            anchors.bottomMargin: 20
                            color: Config.foreground
                            radius: 25

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
                                        font.pixelSize: 16
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
                                anchors.margins: 20
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
                            height: parent.height - 20
                            width: parent.width / 2 - 30
                            anchors.right: parent.right
                            anchors.rightMargin: 20
                            model: clipboardPopup.clipboardModel
                            spacing: 20
                            clip: true
                            currentIndex: Config.currentClipboardIndex

                            property int listHeight: (height - 80) / 5

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
                                        radius: 25
                                        opacity: 1

                                        Behavior on opacity {
                                            NumberAnimation {
                                                duration: 200
                                                easing.type: Easing.InOutQuad
                                            }
                                        }
                                    }

                                    Text {
                                        anchors.leftMargin: 80
                                        anchors.left: parent.left
                                        anchors.top: listIcon.top
                                        text: (modelData.filePath === "null") ? "Text" : "Image"
                                        font.pixelSize: 16
                                        font.bold: true
                                        font.family: Config.fontFamily
                                        color: Config.text
                                    }

                                    Image {
                                        id: listIcon
                                        source: (modelData.filePath === "null") ? "../logo/text.svg" : "../logo/image.svg"
                                        anchors.left: parent.left
                                        anchors.leftMargin: 20
                                        anchors.verticalCenter: parent.verticalCenter
                                        width: 45
                                        height: 45
                                        sourceSize.height: 45
                                        sourceSize.width: 45
                                        fillMode: Image.PreserveAspectFit
                                    }

                                    Text {
                                        id: listTime
                                        anchors.bottom: listIcon.bottom
                                        anchors.left: parent.left
                                        anchors.leftMargin: 80
                                        text: modelData.recorded.split(".")[0]
                                        font.pixelSize: 12
                                        font.bold: false
                                        font.family: Config.fontFamily
                                        color: Config.text
                                        opacity: 0.6
                                    }

                                    Rectangle {
                                        id: closeRect
                                        anchors.right: parent.right
                                        anchors.rightMargin: 20
                                        anchors.verticalCenter: parent.verticalCenter
                                        width: 24
                                        height: 24
                                        color: Config.closeColor
                                        radius: height / 2
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
                                            font.pixelSize: 14
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
                                        anchors.rightMargin: 20
                                        anchors.verticalCenter: parent.verticalCenter
                                        width: 24
                                        height: 24
                                        color: Config.expandedColor
                                        radius: height / 2
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
                                            font.pixelSize: 14
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
                                        anchors.rightMargin: 20
                                        anchors.verticalCenter: parent.verticalCenter
                                        width: 24
                                        height: 24
                                        color: Config.pinColor
                                        radius: height / 2
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
                                            font.pixelSize: 14
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
                            width: parent.width / 2 - 30
                            height: clipboardListView.listHeight
                            anchors.left: parent.left
                            anchors.leftMargin: 20
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
                                            font.pixelSize: 20
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
                                            width: clipboardPopup.filterMode === mode ? 22 : 0
                                            height: 5
                                            color: Config.text
                                            radius: height / 2
                                            anchors.top: buttonIcon.bottom
                                            anchors.topMargin: 5
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
                            radius: 25
                            z: -1
                        }
                    }
                }
            }
        }
    }
}
