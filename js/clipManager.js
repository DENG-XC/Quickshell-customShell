const fs = require("fs");
const path = require("path");

const historyFile = path.join(
  process.env.HOME,
  ".config/clipse/clipboard_history.json",
);

function loadData() {
  try {
    if (!fs.existsSync(historyFile)) return null;
    const fileContent = fs.readFileSync(historyFile, "utf-8");
    return JSON.parse(fileContent);
  } catch (error) {
    console.error("cant read file:", error);
    return null;
  }
}

function saveData(data) {
  const tmpFile = historyFile + ".tmp";
  const jsonString = JSON.stringify(data, null, 4);
  fs.writeFileSync(tmpFile, jsonString, "utf-8");
  fs.renameSync(tmpFile, historyFile);
}

function deleteItem(recordedTime) {
  let data = loadData();
  if (!data) return;

  const list = data.clipboardHistory || [];
  const newList = list.filter((item) => item.recorded !== recordedTime);
  data.clipboardHistory = newList;
  saveData(data);
  console.log("Item Deleted");
}

function togglePin(recordedTime) {
  let data = loadData();
  if (!data) return;

  const list = data.clipboardHistory || [];
  const newListPin = list.find((item) => item.recorded === recordedTime);

  if (newListPin) {
    newListPin.pinned = !newListPin.pinned;
    saveData(data);
    console.log("toggle Pin");
  }
}

const args = process.argv.slice(2);

if (args.length < 2) {
  console.log("how to use: node clipManager.js [delete|pin] [recordedTime]");
  process.exit(1);
}

const action = args[0];
const recordedTime = args[1];

if (action === "delete") {
  deleteItem(recordedTime);
} else if (action === "pin") {
  togglePin(recordedTime);
}
