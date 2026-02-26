import json
import sys

import psutil


def get_system_info():
    cpu_usage = psutil.cpu_percent(interval=0.1)
    memory_usage = psutil.virtual_memory().percent
    disk_usage = psutil.disk_usage("/").percent

    cpu_temp = 0

    try:
        temp = psutil.sensors_temperatures()
        for name in ["coretemp", "k10temp", "acpitz", "zenpower"]:
            if name in temp:
                cpu_temp = temp[name][0].current
                break
    except Exception as e:
        sys.stderr.write(f"Error getting CPU temperature: {e}\n")

    data = {
        "cpu_usage": cpu_usage,
        "memory_usage": memory_usage,
        "disk_usage": disk_usage,
        "cpu_temp": cpu_temp,
    }

    print(json.dumps(data))


if __name__ == "__main__":
    get_system_info()
