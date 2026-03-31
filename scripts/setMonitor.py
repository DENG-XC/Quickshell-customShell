import json
import subprocess
import sys


def set_mode(data):
    for item in data:
        name = item["name"]
        mode = item.get("currentMode")
        scale = item.get("scale")

        if mode:
            subprocess.run(
                ["niri", "msg", "output", name, "mode", mode], capture_output=True
            )
        if scale:
            subprocess.run(
                ["niri", "msg", "output", name, "scale", scale], capture_output=True
            )


if __name__ == "__main__":
    args = sys.argv[1:]

    if args:
        if len(args) <= 1:
            data = json.loads(args[0])
            set_mode(data)
