import json
import os
import re

# from turtle import Turtle

home = os.path.expanduser("~")
niri_file = os.path.join(home, ".config", "niri", "config.kdl")


def get_niri_info():
    with open(niri_file, "r", encoding="utf-8") as f:
        content = f.read()

    result = {}

    # capture output #获取output信息
    screens = []
    screen_pattern = r'output\s+"([^"]+)"\s*\{([^}]*)\}'

    for match in re.finditer(screen_pattern, content):
        name = match.group(1)
        block = match.group(2)

        screen_info = {
            "name": name,
            "width": 0,
            "height": 0,
            "refresh_rate": 0.0,
            "focus": False,
        }

        mode_match = re.search(r'mode\s+"(\d+)x(\d+)@([\d.]+)"', block)
        if mode_match:
            screen_info["width"] = int(mode_match.group(1))
            screen_info["height"] = int(mode_match.group(2))
            screen_info["refresh_rate"] = float(mode_match.group(3))

        if "focus-at-startup" in block:
            screen_info["focus"] = True

        screens.append(screen_info)

    result["screens"] = screens

    # capture layout #获取layout信息
    layout = {}
    layout_pattern = r"layout\s*\{([^}]*(?:\{[^}]*\}[^}]*)*)\}"

    layout_match = re.search(layout_pattern, content)
    layout_content = layout_match.group(1)
    if layout_match:
        gaps_match = re.search(r"gaps\s+(\d+)", layout_content)
        layout["gaps"] = int(gaps_match.group(1))

    result["layout"] = layout

    # capture radius #捕获圆角度数
    corner_radius = {}
    corner_pattern = r"geometry-corner-radius\s+(\d+)"

    corner_match = re.search(corner_pattern, content)
    if corner_match:
        corner_radius["radius"] = int(corner_match.group(1))

    result["corner_radius"] = corner_radius

    # capture animations #捕获动画数据

    animations = {}
    ani_match = re.search(r"animations\s+\{([^}]*)\}", content)
    ani_content = ani_match.group(1)

    if ani_content:
        ani_enable = re.search(r"^(\s*)on(\s*)$", ani_content, flags=re.MULTILINE)

        if ani_enable:
            animations["enable"] = True
        else:
            animations["enable"] = False

        ani_slowdown = re.search(r"slowdown\s+([\d.]+)", ani_content)
        if ani_slowdown:
            animations["slowdown"] = float(ani_slowdown.group(1))

    result["animations"] = animations

    # capture focus_ring
    focus_ring = {}
    focus_pattern = r"focus-ring\s*\{([^}]*)\}"

    focus_match = re.search(focus_pattern, content)
    focus_content = focus_match.group(1)

    focus_lines = focus_content.split("\n")
    for line in focus_lines:
        lines = line.strip()
        if "off" in lines:
            focus_ring["enable"] = False
        elif "on" in lines:
            if lines.startswith("//"):
                focus_ring["enable"] = False
            else:
                focus_ring["enable"] = True

        if lines.startswith("width"):
            width_match = re.search(r"width\s+(\d+)", lines)
            focus_ring["width"] = int(width_match.group(1))

        if lines.startswith("active-color"):
            color_match = re.search(r'active-color\s+"([^"]*)"', lines)
            focus_ring["color"] = color_match.group(1)

    result["focus-ring"] = focus_ring

    # capture border # 获取border信息
    border = {}
    border_pattern = r"border\s*\{([^}]*)\}"

    border_match = re.search(border_pattern, content)
    border_content = border_match.group(1)

    border_lines = border_content.split("\n")
    for line in border_lines:
        lines = line.strip()
        if "off" in lines:
            border["enable"] = False
        elif "on" in lines:
            if lines.startswith("//"):
                border["enable"] = False
            else:
                border["enable"] = True

        if lines.startswith("width"):
            width_match = re.search(r"width\s+(\d+)", lines)
            border["width"] = int(width_match.group(1))

        if lines.startswith("active-color"):
            color_match = re.search(r'color\s+"([^"]*)"', lines)
            border["color"] = color_match.group(1)

    result["border"] = border

    # capture shadow # 获取shadow信息
    shadow = {}
    shadow_pattern = r"shadow\s*\{([^}]*)\}"

    shadow_match = re.search(shadow_pattern, content)
    shadow_content = shadow_match.group(1)

    shadow_lines = shadow_content.split("\n")
    for line in shadow_lines:
        lines = line.strip()
        if "on" in lines:
            if lines.startswith("//"):
                shadow["enable"] = False
            else:
                shadow["enable"] = True
        elif "off" in lines:
            shadow["enable"] = False

        if lines.startswith("softness"):
            softness_match = re.search(r"softness\s+(\d+)", lines)
            shadow["softness"] = int(softness_match.group(1))

        if lines.startswith("spread"):
            spread_match = re.search(r"spread\s+(\d+)", lines)
            shadow["spread"] = spread_match.group(1)

        if lines.startswith("offset"):
            offset_match = re.search(r"offset\s*x=(\d+)\s*y=(\d+)", lines)
            shadow["offset"] = {
                "x": int(offset_match.group(1)),
                "y": int(offset_match.group(2)),
            }

        if lines.startswith("color"):
            color_match = re.search(r'color\s+"([^"]*)"', lines)
            shadow["color"] = color_match.group(1)

    result["shadow"] = shadow

    # capture sturts # 获取struts信息
    struts = {}
    struts_pattern = r"struts\s*\{([^}]*)\}"

    struts_match = re.search(struts_pattern, content)
    struts_content = struts_match.group(1)

    struts_enable = False

    for line in struts_content.split("\n"):
        lines = line.strip()

        if not lines:
            continue

        if not lines.startswith("//"):
            struts_enable = True

        if "top" in lines:
            top_match = re.search(r"top\s+(\d+)", lines)
            struts["top"] = int(top_match.group(1))

        if "left" in lines:
            left_match = re.search(r"left\s+(\d+)", lines)
            struts["left"] = int(left_match.group(1))

        if "right" in lines:
            right_match = re.search(r"right\s+(\d+)", lines)
            struts["right"] = int(right_match.group(1))

        if "bottom" in lines:
            bottom_match = re.search(r"bottom\s+(\d+)", lines)
            struts["bottom"] = int(bottom_match.group(1))

    if struts_enable:
        struts["enabled"] = True
    else:
        struts["enabled"] = False

    result["struts"] = struts
    return result


if __name__ == "__main__":
    result = get_niri_info()
    print(json.dumps(result, indent=2))
