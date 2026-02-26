pragma Singleton

import QtQuick
import Quickshell

Singleton {
    id: searchHelper

    function fuzzyMatch(query, text) {
        query = query.toLowerCase();
        text = text.toLowerCase();

        let j = 0;
        for (let i = 0; i < text.length && j < query.length; i++) {
            if (text[i] === query[j]) {
                j++;
            }
        }
        return j === query.length;
    }

    function updateFilter(query) {
        appLaunchersModel.clear();

        if (!query || query.trim() === "") {
            for (let i = 0; i < DesktopEntries.applications.count; i++) {
                appLaunchersModel.append(DesktopEntries.applications.get(i));
            }
            return;
        }

        for (let i = 0; i < DesktopEntries.applications.count; i++) {
            let app = DesktopEntries.applications.get(i);
            if (app.name && fuzzyMatch(query, app.name)) {
                appLaunchersModel.append(app);
            }
        }
    }
}
