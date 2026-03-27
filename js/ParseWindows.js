function parseWindowsOutput(output, model) {
  if (!output || output.trim() === "") {
    UpdateRunningWindows.updateRunningWindows(model, []);
    return;
  }

  const lines = output.split("\n");

  const parsedWindows = [];
  const appIdMapped = {
    "com.gitee.gmg137.NeteaseCloudMusicGtk4":
      "com.github.gmg137.netease-cloud-music-gtk",
  };

  let currentWindow = null;

  for (let i = 0; i < lines.length; i++) {
    const line = lines[i];
    const trimmedLine = line.trim();

    const idMatch = line.match(/^Window ID\s+(\S+):\s*(?:\((focused)\))?/);
    if (idMatch) {
      if (currentWindow) {
        parsedWindows.push(currentWindow);
      }
      currentWindow = {
        windowId: idMatch[1],
        appId: "",
        focused: !!idMatch[2],
        icon: "",
      };
      continue;
    }

    if (currentWindow) {
      const appIdMatch = line.match(/App ID:\s*"([^"]+)"/);
      if (appIdMatch) {
        const originalAppId = appIdMatch[1];
        currentWindow.appId = originalAppId;

        const mappedId = appIdMapped[originalAppId] || originalAppId;
        if (originalAppId) {
          try {
            let appEntry = DesktopEntries.heuristicLookup(originalAppId);
            if (appEntry) {
              currentWindow.appId = appEntry.name;
              currentWindow.icon = appEntry.icon;
            } else {
              let entry = DesktopEntries.applications.values;
              if (entry) {
                for (let j = 0; j < entry.length; j++) {
                  const de = entry[j];
                  if (de.id.toLowerCase().includes(mappedId.toLowerCase())) {
                    currentWindow.appId = de.name;
                    currentWindow.icon = de.icon;
                    break;
                  }
                }
              }
            }
          } catch (e) {
            console.error("Error parsing window:", e);
          }
        }
      }
    }
  }

  if (currentWindow) {
    parsedWindows.push(currentWindow);
  }

  UpdateRunningWindows.updateRunningWindows(model, parsedWindows);
}
