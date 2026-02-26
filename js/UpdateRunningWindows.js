function updateRunningWindows(model, newWindows) {
  for (let i = model.count - 1; i >= 0; i--) {
    const item = model.get(i);
    let found = newWindows.some((w) => w.windowId === item.windowId);
    if (!found) model.remove(i);
  }

  for (let i = 0; i < model.count; i++) {
    const item = model.get(i);
    let match = newWindows.find((w) => w.windowId === item.windowId);
    if (match) {
      if (match.appId !== item.appId)
        model.setProperty(i, "appId", match.appId);
      if (match.focused !== item.focused)
        model.setProperty(i, "focused", match.focused);
    }
  }

  for (let k = 0; k < newWindows.length; k++) {
    let w = newWindows[k];
    let idx = -1;
    for (let i = 0; i < model.count; i++) {
      if (model.get(i).windowId === w.windowId) {
        idx = i;
        break;
      }
    }
    if (idx === -1) {
      model.insert(k, {
        windowId: w.windowId,
        appId: w.appId,
        focused: w.focused,
        icon: w.icon,
      });
    } else if (idx !== k) {
      model.move(idx, k, 1);
    }
  }
}
