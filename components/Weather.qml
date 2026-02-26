import Quickshell
import QtQuick
import QtQuick.Layouts

Item {
    id: weatherRoot
    anchors.fill: parent

    Item {
        id: todayWeather
        anchors.horizontalCenter: parent.horizontalCenter
        width: parent.width - 40
        height: parent.height / 2 - 25
        anchors.topMargin: 20
        anchors.top: parent.top

        Text {
            id: todayIcon
            text: WeatherService.icon
            anchors.top: parent.top
            anchors.right: parent.right
            font.pixelSize: 130
            font.family: Config.fontFamily
        }

        Text {
            id: todayTemp
            text: WeatherService.maxTemp + " " + "°"
            anchors.top: todayIcon.top
            anchors.topMargin: 10
            anchors.left: parent.left
            anchors.leftMargin: 10
            font.pixelSize: 46
            font.bold: true
            font.family: Config.fontFamily
            color: Config.text
        }

        Text {
            id: cityName
            text: WeatherService.cityName
            anchors.bottom: todayIcon.bottom
            anchors.bottomMargin: 25
            anchors.left: parent.left
            anchors.leftMargin: 10
            font.pixelSize: 16
            font.bold: true
            font.family: Config.fontFamily
            color: Config.text
            opacity: 0.6
        }

        Text {
            id: todayDescription
            text: WeatherService.desc
            anchors.bottom: cityName.top
            anchors.bottomMargin: 0
            anchors.left: parent.left
            anchors.leftMargin: 10
            font.pixelSize: 14
            font.bold: false
            font.family: Config.fontFamily
            color: Config.text
            opacity: 0.6
        }

        Text {
            id: todayminTemp
            text: "/" + " " + WeatherService.minTemp + " " + "°"
            anchors.left: todayTemp.right
            anchors.bottom: todayTemp.bottom
            anchors.leftMargin: 0
            font.pixelSize: 18
            font.bold: true
            font.family: Config.fontFamily
            color: Config.text
            opacity: 0.6
        }
    }

    ListView {
        id: forecastList
        width: parent.width - 40
        height: parent.height / 2 - 20
        anchors.top: todayWeather.bottom
        //anchors.bottom: parent.bottom
        //anchors.bottomMargin: 20
        anchors.horizontalCenter: parent.horizontalCenter
        model: WeatherService.weatherModel
        spacing: 20
        clip: true
        delegate: Rectangle {
            implicitHeight: forecastList.height / 2 - 10
            implicitWidth: forecastList.width
            radius: 25
            color: Config.foreground

            RowLayout {
                anchors.fill: parent
                uniformCellSizes: true

                Text {
                    id: forecastDay
                    text: dayName
                    Layout.alignment: Qt.AlignLeft
                    Layout.leftMargin: 20
                    font.pixelSize: 14
                    font.bold: true
                    font.family: Config.fontFamily
                    color: Config.text
                    opacity: 1
                }

                Text {
                    id: forecastTemp
                    text: maxTemp + "°" + "/" + " " + minTemp + "°"
                    Layout.alignment: Qt.AlignCenter
                    font.pixelSize: 14
                    font.bold: true
                    font.family: Config.fontFamily
                    color: Config.text
                    opacity: 1
                }

                Text {
                    id: forecastIcon
                    text: icon
                    Layout.alignment: Qt.AlignRight
                    Layout.rightMargin: 20
                    font.pixelSize: 36
                    font.family: Config.fontFamily
                }
            }
        }
    }
}
