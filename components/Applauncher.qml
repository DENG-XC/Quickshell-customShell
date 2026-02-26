import QtQuick
import QtQuick.Layouts
import QtQuick.Controls
import Quickshell
import "../js/UpdateFilter.js" as UpdateFilter
import "../js/LaunchSelectedApp.js" as LaunchSelectedApp

Rectangle {
                            id: applauncher
                            color: leftPanel.collapsed ? isHovered ? Config.textselect : "transparent" : Config.foreground
                            Layout.preferredWidth: leftPanel.collapsed ? parent.width - 20 : parent.width
                            Layout.preferredHeight: leftPanel.collapsed ? parent.width - 20 : Config.toggleAppLauncher ? expandedHeight : baseHeight
                            Layout.fillHeight: false
                            Layout.topMargin: leftPanel.collapsed ? 20 : 0
                            Layout.alignment: Qt.AlignCenter
                            radius: leftPanel.collapsed ? 10 : 25
                            clip: true

                            property real baseHeight: mainLayout.height / 25
                            property real expandedHeight: Math.round(mainLayout.height / 4.2)
                            property bool isHovered: false

                            Behavior on Layout.preferredHeight {

                                enabled: !leftPanel.collapsed

                                NumberAnimation {
                                    easing.type: Easing.InOutQuad
                                    duration: 200
                                }
                            }

                            Behavior on color {
                                ColorAnimation {
                                    easing.type: Easing.OutQuad
                                    duration: 200
                                }
                            }

                            GlobalMouseArea {
                                id: globalMouseArea
                            }

                            MouseArea {
                                id: startAppLauncher
                                anchors.fill: parent
                                hoverEnabled: true
                                enabled: leftPanel.collapsed
                                cursorShape: leftPanel.collapsed ? Qt.PointingHandCursor : Qt.ArrowCursor
                                onClicked: {
                                    leftPanel.collapsed = false;
                                    Config.toggleCollapseApp = true;
                                    Config.toggleAppLauncher = true;
                                    Config.toggleLeftPanel = true;
                                }
                                onEntered: {
                                    parent.isHovered = true;
                                }
                                onExited: {
                                    parent.isHovered = false;
                                }
                            }

                            Item {
                                id: appIconContainer
                                implicitWidth: appLauncherBorder.width
                                anchors.top: appLauncherBorder.bottom
                                anchors.horizontalCenter: parent.horizontalCenter
                                anchors.bottom: parent.bottom
                                anchors.topMargin: 10
                                anchors.bottomMargin: 10
                                visible: leftPanel.collapsed ? false : Config.toggleAppLauncher ? true : false

                                GridView {
                                    id: appIconGrid
                                    anchors.fill: parent
                                    model: Config.filteredAppsModel
                                    cellHeight: parent.height / 2
                                    cellWidth: parent.width / 3
                                    clip: true
                                    boundsBehavior: Flickable.StopAtBounds
                                    currentIndex: Config.currentAppIndex

                                    delegate: Item {
                                        implicitWidth: appIconGrid.cellWidth
                                        implicitHeight: appIconGrid.cellHeight

                                        property bool isHovered: false
                                        property bool isSelected: appIconGrid.currentIndex === index

                                        SequentialAnimation {
                                            id: clickAnimation
                                            running: false

                                            ParallelAnimation {
                                                NumberAnimation {
                                                    target: appItem
                                                    property: "scale"
                                                    from: 1
                                                    to: 0.85
                                                    duration: 100
                                                    easing.type: Easing.OutQuad
                                                }

                                                NumberAnimation {
                                                    target: appListBackground
                                                    property: "scale"
                                                    from: 1
                                                    to: 0.85
                                                    duration: 100
                                                    easing.type: Easing.OutQuad
                                                }
                                            }

                                            PauseAnimation {
                                                duration: 50
                                            }

                                            ParallelAnimation {
                                                NumberAnimation {
                                                    target: appItem
                                                    property: "scale"
                                                    from: 0.85
                                                    to: 1
                                                    duration: 100
                                                    easing.type: Easing.OutQuad
                                                }

                                                NumberAnimation {
                                                    target: appListBackground
                                                    property: "scale"
                                                    from: 0.85
                                                    to: 1
                                                    duration: 100
                                                    easing.type: Easing.OutQuad
                                                }
                                            }

                                            onFinished: {
                                                modelData.exec.execute();
                                                searchInput.text = "";
                                            }
                                        }

                                        Rectangle {
                                            id: appListBackground
                                            anchors.fill: parent
                                            color: Config.textHover
                                            radius: 25
                                            scale: 1
                                            opacity: isSelected ? 1 : (isHovered ? 0.3 : 0)

                                            Behavior on opacity {
                                                NumberAnimation {
                                                    duration: 200
                                                }
                                            }
                                        }

                                        Item {
                                            id: appItem
                                            scale: 1
                                            anchors.fill: parent

                                            Image {
                                                id: appListIcon
                                                anchors.horizontalCenter: parent.horizontalCenter
                                                y: parent.height / 2 - 36
                                                source: modelData.icon
                                                width: 52
                                                height: 52
                                                sourceSize.width: 52
                                                sourceSize.height: 52
                                                asynchronous: true
                                                fillMode: Image.PreserveAspectFit
                                            }

                                            Text {
                                                id: appListName
                                                text: modelData.name
                                                anchors.horizontalCenter: parent.horizontalCenter
                                                horizontalAlignment: Text.AlignHCenter
                                                anchors.top: appListIcon.bottom
                                                width: parent.width * 0.8
                                                anchors.topMargin: 10
                                                font.pixelSize: 16
                                                font.bold: true
                                                font.family: Config.fontFamily
                                                color: Config.text
                                                wrapMode: Text.NoWrap
                                                elide: Text.ElideRight
                                            }
                                        }

                                        MouseArea {
                                            anchors.fill: parent
                                            hoverEnabled: true

                                            onEntered: {
                                                isHovered = true;
                                            }
                                            onExited: {
                                                isHovered = false;
                                            }
                                            onClicked: {
                                                Config.currentAppIndex = index;
                                                clickAnimation.start();
                                            }
                                        }
                                    }
                                }
                            }

                            Rectangle {
                                id: appLauncherBorder
                                color: Config.text
                                y: parent.baseHeight
                                implicitHeight: 1
                                implicitWidth: parent.width - 40
                                anchors.horizontalCenter: parent.horizontalCenter
                                visible: leftPanel.collapsed ? false : Config.toggleAppLauncher ? true : false
                            }

                            RowLayout {
                                height: leftPanel.collapsed ? parent.height : parent.baseHeight
                                width: parent.width
                                spacing: leftPanel.collapsed ? 0 : 10

                                Text {
                                    id: searchIcon
                                    text: ""
                                    color: Config.text
                                    font.pixelSize: 16
                                    font.bold: true
                                    font.family: Config.fontFamily
                                    Layout.alignment: Qt.AlignVCenter
                                    Layout.leftMargin: leftPanel.collapsed ? parent.width / 2 - width / 2 : 20
                                }

                                TextField {
                                    id: searchInput
                                    background: Rectangle {
                                        color: "transparent"
                                    }
                                    placeholderText: "Search"
                                    placeholderTextColor: Config.text
                                    height: parent.height
                                    color: Config.text
                                    focus: Config.toggleAppLauncher
                                    font.pixelSize: 16
                                    font.bold: true
                                    font.family: Config.fontFamily
                                    Layout.fillWidth: true
                                    Layout.alignment: Qt.AlignVCenter
                                    visible: leftPanel.collapsed ? false : true

                                    Timer {
                                        id: panelTimer
                                        interval: 350
                                        running: false
                                        onTriggered: {
                                            Config.toggleLeftPanel = false
                                            Config.delayLoader.running = true;
                                        }
                                    }

                                    Timer {
                                        id: collapseTimer
                                        interval: 300
                                        running: false
                                        onTriggered: {
                                            Config.toggleCollapseApp = false;
                                            leftPanel.collapsed = true;
                                        }
                                    }

                                    Keys.onPressed: function (event) {
                                        if (event.key === Qt.Key_Escape) {
                                            event.accepted = true;
                                            if (leftPanel.ispin && Config.toggleCollapseApp) {
                                                Config.toggleAppLauncher = false;
                                                collapseTimer.start()
                                            } else if (leftPanel.ispin) {
                                                Config.toggleAppLauncher = false;
                                            } else if (leftPanel.ispin && Config.toggleCollapseApp) {
                                                Config.toggleAppLauncher = false
                                                collapseTimer.start()
                                            } else if (Config.toggleCollapseApp && !leftPanel.collapsed) {
                                                Config.toggleAppLauncher = false
                                                panelTimer.start()
                                                collapseTimer.start()
                                            } else {
                                                Config.toggleAppLauncher = false
                                                panelTimer.start()
                                            }
                                        } else if (event.key === Qt.Key_Down) {
                                            event.accepted = true;
                                            if (Config.filteredAppsModel.length > 0) {
                                                var newIndex = Config.currentAppIndex + 3;
                                                if (newIndex >= Config.filteredAppsModel.length) {
                                                    newIndex = Config.filteredAppsModel.length - 1;
                                                }
                                                Config.currentAppIndex = newIndex;
                                                appIconGrid.positionViewAtIndex(newIndex, GridView.Contain);
                                            }
                                        } else if (event.key === Qt.Key_Up) {
                                            event.accepted = true;
                                            if (Config.filteredAppsModel.length > 0) {
                                                var newIndex = Config.currentAppIndex - 3;
                                                if (newIndex < 0) {
                                                    newIndex = 0;
                                                }
                                                Config.currentAppIndex = newIndex;
                                                appIconGrid.positionViewAtIndex(newIndex, GridView.Contain);
                                            }
                                        } else if (event.key === Qt.Key_Right) {
                                            event.accepted = true;
                                            if (Config.filteredAppsModel.length > 0) {
                                                var newIndex = Config.currentAppIndex + 1;
                                                if (newIndex >= Config.filteredAppsModel.length) {
                                                    newIndex = Config.filteredAppsModel.length - 1;
                                                }
                                                Config.currentAppIndex = newIndex;
                                                appIconGrid.positionViewAtIndex(newIndex, GridView.Contain);
                                            }
                                        } else if (event.key === Qt.Key_Left) {
                                            event.accepted = true;
                                            if (Config.filteredAppsModel.length > 0) {
                                                var newIndex = Config.currentAppIndex - 1;
                                                if (newIndex < 0) {
                                                    newIndex = 0;
                                                }
                                                Config.currentAppIndex = newIndex;
                                                appIconGrid.positionViewAtIndex(newIndex, GridView.Contain);
                                            }
                                        } else if (event.key === Qt.Key_Return || event.key === Qt.Key_Enter) {
                                            event.accepted = true;
                                            if (leftPanel.ispin && Config.toggleCollapseApp) {
                                                Config.toggleAppLauncher = false;
                                                LaunchSelectedApp.launchSelectedApp(Config.currentAppIndex, Config.filteredAppsModel)
                                                searchInput.text = ""
                                                collapseTimer.start()
                                            } else if (leftPanel.ispin) {
                                                LaunchSelectedApp.launchSelectedApp(Config.currentAppIndex, Config.filteredAppsModel);
                                                searchInput.text = "";
                                                Config.toggleAppLauncher = false;
                                            } else if (Config.toggleCollapseApp && !leftPanel.collapsed) {
                                                LaunchSelectedApp.launchSelectedApp(Config.currentAppIndex, Config.filteredAppsModel);
                                                searchInput.text = "";
                                                Config.toggleAppLauncher = false;
                                                panelTimer.start()
                                                collapseTimer.start()
                                            } else {
                                                LaunchSelectedApp.launchSelectedApp(Config.currentAppIndex, Config.filteredAppsModel);
                                                searchInput.text = "";
                                                Config.toggleAppLauncher = false;
                                                panelTimer.start()
                                            }
                                        }
                                    }

                                    onPressed: {
                                        Config.toggleAppLauncher = true;
                                    }

                                    onTextChanged: {
                                        UpdateFilter.updateFilter(text);
                                    }
                                }
                            }
                        }
