import json
import os
import sys

HISTORY_FILE = os.path.expanduser("~/.config/clipse/clipboard_history.json")


def load_date():
    if not os.path.exists(HISTORY_FILE):
        print("clipse not installed")
        return None

    try:
        with open(HISTORY_FILE, "r", encoding="utf-8") as f:
            return json.load(f)

    except Exception as e:
        print(f"cant read history file: {e}")
        return None


def replace_data(data):
    try:
        tmp_file = HISTORY_FILE + ".tmp"
        with open(tmp_file, "w", encoding="utf-8") as f:
            json.dump(data, f, indent=4)

        os.replace(tmp_file, HISTORY_FILE)
    except Exception as e:
        print(f"error replace data: {e}")


def delete_item(recorded_time):
    data = load_date()
    if not data:
        return

    history_list = data.get("clipboardHistory", [])
    target_time = recorded_time.strip()

    new_list = [
        item for item in history_list if item["recorded"].strip() != target_time
    ]

    data["clipboardHistory"] = new_list
    replace_data(data)
    print("delete item success")


def toggle_pin(recorded_time):
    data = load_date()
    if not data:
        return

    history_list = data.get("clipboardHistory", [])
    target_time = recorded_time.strip()

    found = False

    for item in history_list:
        if item["recorded"].strip() == target_time:
            item["pinned"] = not item["pinned"]
            found = True
            break

    if found:
        replace_data(data)
        print("toggle pin success")
    else:
        print("pin fail")


if __name__ == "__main__":
    args = sys.argv[1:]

    if len(args) < 2:
        print("Usage: python clipManager.py [delete|pin] [recordedTime]")
        sys.exit(1)
    elif len(args) > 2:
        print("Too many arguments")
        sys.exit(1)

    action = args[0]

    recorded_time = args[1]

    if action == "delete":
        delete_item(recorded_time)
    elif action == "pin":
        toggle_pin(recorded_time)
