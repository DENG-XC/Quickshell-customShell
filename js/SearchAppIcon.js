function searchAppIcon(appIcon) {
  if (!appIcon || appIcon === "") {
    console.log("Invalid appId");
    return "";
  }

  const lowerId = appIcon.toLowerCase();

  try {
    let iconPathQs = Quickshell.iconPath(appIcon, true);
    if (iconPathQs && iconPathQs !== "") {
      return iconPathQs;
    }

    iconPathQs = Quickshell.iconPath(lowerId, true);
    if (iconPathQs && iconPathQs !== "") {
      return iconPathQs;
    }
  } catch (error) {
    console.error("Error fetching icon:", error);
  }

  console.warn("Icon not found for appId:", appIcon);
  return "";
}
