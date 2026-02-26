function fuzzySearch(inPutText, appName) {
  let lowerInput = inPutText.toLowerCase();
  let lowerName = appName.toLowerCase();

  let inPutIndex = 0;

  for (let i = 0; i < lowerName.length; i++) {
    if (lowerName[i] === lowerInput[inPutIndex]) {
      inPutIndex++;
    }
    if (inPutIndex === lowerInput.length) {
      return true;
    }
  }

  return false;
}

function updateFilter(inPut) {
  let lowerInput = (inPut || "").toLowerCase();
  const apps = DesktopEntries.applications.values;
  const iconMapped = {
    "btop++": "/usr/share/icons/hicolor/256x256/apps/btop.png",
  };
  let filterApps = [];

  if (lowerInput === "") {
    filterApps = apps;
  } else {
    filterApps = apps.filter((app) => fuzzySearch(lowerInput, app.name));
  }

  Config.filteredAppsModel = filterApps.map((app) => ({
    name: app.name,
    icon: Quickshell.iconPath(app.icon, true) || iconMapped[app.name],
    exec: app,
  }));

  Config.currentAppIndex = 0;
}
