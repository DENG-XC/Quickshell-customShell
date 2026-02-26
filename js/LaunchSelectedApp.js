function launchSelectedApp(appIndex, appsModel) {
  if (appIndex >= 0 && appIndex < appsModel.length) {
    let app = appsModel[appIndex];
    if (app && app.exec) {
      app.exec.execute();
      leftPanel.appfocused = false;
    }
  }
}
