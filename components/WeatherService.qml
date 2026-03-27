pragma Singleton
import QtQuick
import Quickshell

Singleton {
    id: service

    property string cityName: "Loading..."
    property int maxTemp: 0
    property int minTemp: 0
    property string icon: ""
    property string desc: ""
    property alias weatherModel: weatherModel

    ListModel {
        id: weatherModel
    }

    function getLocation() {
        const xhr = new XMLHttpRequest();
        xhr.open("GET", "http://ip-api.com/json");
        xhr.onreadystatechange = function () {
            if (xhr.readyState === XMLHttpRequest.DONE) {
                if (xhr.status === 200) {
                    let location = JSON.parse(xhr.responseText);
                    service.cityName = location.city;
                    getWeather(location.lat, location.lon);
                } else {
                    weatherTimer.running = true;
                    console.warn("Error getting location, try angain");
                }
            }
        };

        xhr.send();
    }

    function getWeather(lat, lon) {
        const xhr = new XMLHttpRequest();
        xhr.open("GET", "https://api.open-meteo.com/v1/forecast?latitude=" + lat + "&longitude=" + lon + "&current=temperature_2m,weather_code&daily=weather_code,temperature_2m_max,temperature_2m_min&timezone=auto");
        xhr.onreadystatechange = function () {
            if (xhr.readyState === XMLHttpRequest.DONE) {
                if (xhr.status === 200) {
                    let weatherData = JSON.parse(xhr.responseText);
                    service.maxTemp = Math.round(weatherData.daily.temperature_2m_max[0]);
                    service.minTemp = Math.round(weatherData.daily.temperature_2m_min[0]);
                    service.icon = getWeatherIcon(weatherData.daily.weather_code[0]);
                    service.desc = weatherDesc(weatherData.daily.weather_code[0]);
                    weatherModel.clear();

                    for (let i = 1; i < weatherData.daily.time.length; i++) {
                        let dayName = getDayName(weatherData.daily.time[i]);
                        let icon = getWeatherIcon(weatherData.daily.weather_code[i]);
                        let max = Math.round(weatherData.daily.temperature_2m_max[i]);
                        let min = Math.round(weatherData.daily.temperature_2m_min[i]);

                        weatherModel.append({
                            "dayName": dayName,
                            "icon": icon,
                            "maxTemp": max,
                            "minTemp": min
                        });
                    }
                } else {
                    weatherTimer.running = true;
                    console.warn("Error getting weather, try again");
                }
            }
        };

        xhr.send();
    }

    function getWeatherIcon(code) {
        if (code === 0)
            return "☀️";
        if (code >= 1 && code <= 3)
            return "⛅";
        if (code >= 45 && code <= 48)
            return "☁️";
        if (code >= 51 && code <= 67)
            return "🌧️";
        if (code >= 71 && code <= 77)
            return "❄️";
        if (code >= 80 && code <= 82)
            return "🌧️";
        if (code >= 95 && code <= 99)
            return "⛈️";
        return "?";
    }

    function weatherDesc(code) {
        if (code === 0)
            return "Sunny";
        if (code >= 1 && code <= 3)
            return "Cloudy";
        if (code >= 45 && code <= 48)
            return "Fog";
        if (code >= 51 && code <= 67)
            return "Rain";
        if (code >= 71 && code <= 77)
            return "Snow";
        if (code >= 80 && code <= 82)
            return "Heavy Rain";
        if (code >= 95 && code <= 99)
            return "Thunderstorm";
        return "unknown";
    }

    function getDayName(date) {
        let days = ["Sunday", "Monday", "Tuesday", "Wednesday", "Thursday", "Friday", "Saturday"];
        let dateObj = new Date(date);
        return days[dateObj.getDay()];
    }

    Component.onCompleted: {
        getLocation();
    }

    Timer {
        id: weatherTimer
        interval: 3600000
        running: true
        repeat: true
        onTriggered: {
            getLocation();
        }
    }
}
