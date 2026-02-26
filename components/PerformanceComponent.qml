import QtQuick
import Quickshell.Io
import QtQuick.Shapes
import QtQuick.Layouts

Rectangle {
                                    id: performanceContainer
                                    color: Config.background
                                    radius: 25

                                    property int cpuUsage: 0
                                    property int memoryUsage: 0
                                    property int cpuTemperature: 0
                                    property int diskUsage: 0

                                    Process {
                                        id: systemInfo
                                        command: ["python3", "./scripts/systemInfo.py"]
                                        running: true
                                        stdout: StdioCollector {
                                            onStreamFinished: {
                                                let data = JSON.parse(this.text);
                                                performanceContainer.cpuUsage = Math.round(data.cpu_usage);
                                                performanceContainer.memoryUsage = Math.round(data.memory_usage);
                                                performanceContainer.cpuTemperature = Math.round(data.cpu_temp);
                                                performanceContainer.diskUsage = Math.round(data.disk_usage);
                                            }
                                        }
                                    }

                                    Timer {
                                        id: infoTimer
                                        interval: 5000
                                        running: Config.toggleLeftPanel ? true : false
                                        repeat: true
                                        onTriggered: {
                                            systemInfo.running = true;
                                        }
                                    }

                                    ColumnLayout {
                                        width: parent.width / 2 - 30
                                        height: parent.height - 40
                                        anchors.verticalCenter: parent.verticalCenter
                                        x: 20
                                        spacing: 20

                                        Rectangle {
                                            Layout.fillWidth: true
                                            Layout.fillHeight: true
                                            color: Config.foreground
                                            radius: 25

                                            Shape {
                                                id: cpuShape
                                                anchors.centerIn: parent
                                                width: 100
                                                height: 100

                                                ShapePath {
                                                    strokeWidth: 10
                                                    strokeColor: Config.progressColor
                                                    fillColor: "transparent"

                                                    PathAngleArc {
                                                        centerX: cpuShape.width / 2
                                                        centerY: cpuShape.height / 2
                                                        radiusX: cpuShape.width / 2
                                                        radiusY: cpuShape.height / 2
                                                        sweepAngle: 360
                                                    }
                                                }

                                                ShapePath {
                                                    strokeWidth: 10
                                                    strokeColor: Config.textHover
                                                    fillColor: "transparent"
                                                    capStyle: ShapePath.RoundCap

                                                    PathAngleArc {
                                                        centerX: cpuShape.width / 2
                                                        centerY: cpuShape.height / 2
                                                        radiusX: cpuShape.width / 2
                                                        radiusY: cpuShape.height / 2
                                                        startAngle: 90
                                                        sweepAngle: performanceContainer.cpuUsage / 100 * 360
                                                    }
                                                }
                                            }

                                            Text {
                                                id: cpuUsageText
                                                text: performanceContainer.cpuUsage
                                                color: Config.text
                                                anchors.centerIn: parent
                                                font.pixelSize: 22
                                                font.bold: true
                                                font.family: Config.fontFamily
                                            }

                                            Text {
                                                text: "%"
                                                color: Config.text
                                                anchors.top: cpuUsageText.top
                                                anchors.left: cpuUsageText.right
                                                anchors.leftMargin: 5
                                                opacity: 0.6
                                                font.pixelSize: 16
                                                font.bold: true
                                                font.family: Config.fontFamily
                                            }

                                            Text {
                                                text: "CPU"
                                                color: Config.text
                                                anchors.top: cpuUsageText.bottom
                                                anchors.topMargin: 5
                                                anchors.horizontalCenter: cpuUsageText.horizontalCenter
                                                opacity: 0.6
                                                font.pixelSize: 12
                                                font.bold: true
                                                font.family: Config.fontFamily
                                            }
                                        }

                                        Rectangle {
                                            Layout.fillWidth: true
                                            Layout.fillHeight: true
                                            color: Config.foreground
                                            radius: 25

                                            Shape {
                                                id: memoryShape
                                                anchors.centerIn: parent
                                                width: 100
                                                height: 100

                                                ShapePath {
                                                    strokeWidth: 10
                                                    strokeColor: Config.progressColor
                                                    fillColor: "transparent"

                                                    PathAngleArc {
                                                        centerX: memoryShape.width / 2
                                                        centerY: memoryShape.height / 2
                                                        radiusX: memoryShape.width / 2
                                                        radiusY: memoryShape.height / 2
                                                        sweepAngle: 360
                                                    }
                                                }

                                                ShapePath {
                                                    strokeWidth: 10
                                                    strokeColor: Config.textHover
                                                    fillColor: "transparent"
                                                    capStyle: ShapePath.RoundCap

                                                    PathAngleArc {
                                                        centerX: memoryShape.width / 2
                                                        centerY: memoryShape.height / 2
                                                        radiusX: memoryShape.width / 2
                                                        radiusY: memoryShape.height / 2
                                                        startAngle: 90
                                                        sweepAngle: performanceContainer.memoryUsage / 100 * 360
                                                    }
                                                }
                                            }

                                            Text {
                                                id: memoryUsageText
                                                text: performanceContainer.memoryUsage
                                                color: Config.text
                                                anchors.centerIn: parent
                                                font.pixelSize: 22
                                                font.bold: true
                                                font.family: Config.fontFamily
                                            }

                                            Text {
                                                text: "%"
                                                color: Config.text
                                                anchors.top: memoryUsageText.top
                                                anchors.left: memoryUsageText.right
                                                anchors.leftMargin: 5
                                                opacity: 0.6
                                                font.pixelSize: 16
                                                font.bold: true
                                                font.family: Config.fontFamily
                                            }

                                            Text {
                                                text: "RAM"
                                                color: Config.text
                                                anchors.top: memoryUsageText.bottom
                                                anchors.topMargin: 5
                                                anchors.horizontalCenter: memoryUsageText.horizontalCenter
                                                opacity: 0.6
                                                font.pixelSize: 12
                                                font.bold: true
                                                font.family: Config.fontFamily
                                            }
                                        }
                                    }

                                    ColumnLayout {
                                        width: parent.width / 2 - 30
                                        height: parent.height - 40
                                        anchors.verticalCenter: parent.verticalCenter
                                        x: parent.width / 2 + 10
                                        spacing: 20

                                        Rectangle {
                                            Layout.fillWidth: true
                                            Layout.fillHeight: true
                                            color: Config.foreground
                                            radius: 25

                                            Shape {
                                                id: diskShape
                                                anchors.centerIn: parent
                                                width: 100
                                                height: 100

                                                ShapePath {
                                                    strokeWidth: 10
                                                    strokeColor: Config.progressColor
                                                    fillColor: "transparent"

                                                    PathAngleArc {
                                                        centerX: diskShape.width / 2
                                                        centerY: diskShape.height / 2
                                                        radiusX: diskShape.width / 2
                                                        radiusY: diskShape.height / 2
                                                        sweepAngle: 360
                                                    }
                                                }

                                                ShapePath {
                                                    strokeWidth: 10
                                                    strokeColor: Config.textHover
                                                    fillColor: "transparent"
                                                    capStyle: ShapePath.RoundCap

                                                    PathAngleArc {
                                                        centerX: diskShape.width / 2
                                                        centerY: diskShape.height / 2
                                                        radiusX: diskShape.width / 2
                                                        radiusY: diskShape.height / 2
                                                        startAngle: 90
                                                        sweepAngle: performanceContainer.diskUsage / 100 * 360
                                                    }
                                                }
                                            }

                                            Text {
                                                id: diskUsageText
                                                text: performanceContainer.diskUsage
                                                color: Config.text
                                                anchors.centerIn: parent
                                                font.pixelSize: 22
                                                font.bold: true
                                                font.family: Config.fontFamily
                                            }

                                            Text {
                                                text: "%"
                                                color: Config.text
                                                anchors.top: diskUsageText.top
                                                anchors.left: diskUsageText.right
                                                anchors.leftMargin: 5
                                                opacity: 0.6
                                                font.pixelSize: 16
                                                font.bold: true
                                                font.family: Config.fontFamily
                                            }

                                            Text {
                                                text: "DISK"
                                                color: Config.text
                                                anchors.top: diskUsageText.bottom
                                                anchors.topMargin: 5
                                                anchors.horizontalCenter: diskUsageText.horizontalCenter
                                                opacity: 0.6
                                                font.pixelSize: 12
                                                font.bold: true
                                                font.family: Config.fontFamily
                                            }
                                        }

                                        Rectangle {
                                            Layout.fillWidth: true
                                            Layout.fillHeight: true
                                            color: Config.foreground
                                            radius: 25

                                            Shape {
                                                id: tempShape
                                                anchors.centerIn: parent
                                                width: 100
                                                height: 100

                                                ShapePath {
                                                    strokeWidth: 10
                                                    strokeColor: Config.progressColor
                                                    fillColor: "transparent"

                                                    PathAngleArc {
                                                        centerX: tempShape.width / 2
                                                        centerY: tempShape.height / 2
                                                        radiusX: tempShape.width / 2
                                                        radiusY: tempShape.height / 2
                                                        sweepAngle: 360
                                                    }
                                                }

                                                ShapePath {
                                                    strokeWidth: 10
                                                    strokeColor: Config.textHover
                                                    fillColor: "transparent"
                                                    capStyle: ShapePath.RoundCap

                                                    PathAngleArc {
                                                        centerX: tempShape.width / 2
                                                        centerY: tempShape.height / 2
                                                        radiusX: tempShape.width / 2
                                                        radiusY: tempShape.height / 2
                                                        startAngle: 90
                                                        sweepAngle: performanceContainer.cpuTemperature / 100 * 360
                                                    }
                                                }
                                            }

                                            Text {
                                                id: tempText
                                                text: performanceContainer.cpuTemperature
                                                color: Config.text
                                                anchors.centerIn: parent
                                                font.pixelSize: 22
                                                font.bold: true
                                                font.family: Config.fontFamily
                                            }

                                            Text {
                                                text: "°"
                                                color: Config.text
                                                anchors.top: tempText.top
                                                anchors.left: tempText.right
                                                anchors.leftMargin: 5
                                                opacity: 0.6
                                                font.pixelSize: 16
                                                font.bold: true
                                                font.family: Config.fontFamily
                                            }

                                            Text {
                                                text: "TEMP"
                                                color: Config.text
                                                anchors.top: tempText.bottom
                                                anchors.topMargin: 5
                                                anchors.horizontalCenter: tempText.horizontalCenter
                                                opacity: 0.6
                                                font.pixelSize: 12
                                                font.bold: true
                                                font.family: Config.fontFamily
                                            }
                                        }
                                    }
                                }
