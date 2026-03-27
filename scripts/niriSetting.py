import json
import os
import re
import sys

home = os.path.expanduser("~")
niri_file = os.path.join(home, ".config", "niri", "config.kdl")


def set_niri_config(value):
    with open(niri_file, "r", encoding="utf-8") as f:
        content = f.read()

    updated_content = content

    # ===== 修改 layout gaps =====
    layout_match = re.search(
        r"layout\s*\{([^}]*(?:\{[^}]*\}[^}]*)*)\}", content, re.DOTALL
    )
    if layout_match:
        layout_block = layout_match.group(0)
        new_block = re.sub(
            r"gaps\s+\d+", f"gaps {value['layout']['gaps']}", layout_block
        )
        updated_content = updated_content.replace(layout_block, new_block)

    # ===== 修改 corner_radius =====
    corner_radius_match = re.search(
        r"geometry-corner-radius\s+(\d+)", content, re.DOTALL
    )
    if corner_radius_match:
        new_block = re.sub(
            r"geometry-corner-radius\s+\d+",
            f"geometry-corner-radius {value['corner_radius']['radius']}",
            corner_radius_match.group(0),
        )
        updated_content = updated_content.replace(
            corner_radius_match.group(0), new_block
        )

    # ===== 修改 focus-ring =====
    focus_ring_match = re.search(r"focus-ring\s*\{([^}]*)\}", content, re.DOTALL)
    if focus_ring_match:
        focus_block = focus_ring_match.group(0)
        new_block = focus_block

        # 处理 off/on
        if value["focus-ring"]["enable"]:
            new_block = re.sub(
                r"^(\s*)off(\s*)$", r"\1on\2", new_block, flags=re.MULTILINE
            )

            new_block = re.sub(
                r"^(\s*)//\s*off(\s*)$", r"\1on\2", new_block, flags=re.MULTILINE
            )

            new_block = re.sub(
                r"^(\s*)//\s*on(\s*)$", r"\1on\2", new_block, flags=re.MULTILINE
            )

            # 替换 width
            new_block = re.sub(
                r"^(\s*)width\s+\d+",
                rf"\1width {value['focus-ring']['width']}",
                new_block,
                flags=re.MULTILINE,
            )

            # 替换 active-color
            new_block = re.sub(
                r'^(\s*)active-color\s*"[^"]*"',
                rf'\1active-color "{value["focus-ring"]["color"]}"',
                new_block,
                flags=re.MULTILINE,
            )

        else:
            new_block = re.sub(
                r"^(\s*)on(\s*)$", r"\1off\2", new_block, flags=re.MULTILINE
            )

            new_block = re.sub(
                r"^(\s*)//\s*off(\s*)$", r"\1off\2", new_block, flags=re.MULTILINE
            )

            new_block = re.sub(
                r"^(\s*)//\s*on(\s*)$", r"\1off\2", new_block, flags=re.MULTILINE
            )

        updated_content = updated_content.replace(focus_block, new_block)

    # ===== 修改 border =====
    border_match = re.search(r"border\s*\{([^}]*)\}", content, re.DOTALL)
    if border_match:
        border_block = border_match.group(0)
        new_block = border_block

        # 处理 off/on
        if value["border"]["enable"]:
            new_block = re.sub(
                r"^(\s*)off(\s*)$", r"\1on\2", new_block, flags=re.MULTILINE
            )

            new_block = re.sub(
                r"^(\s*)//\s*off(\s*)$", r"\1on\2", new_block, flags=re.MULTILINE
            )

            new_block = re.sub(
                r"^(\s*)//\s*on(\s*)$", r"\1on\2", new_block, flags=re.MULTILINE
            )

            # 替换 width
            new_block = re.sub(
                r"^(\s*)width\s+\d+",
                rf"\1width {value['border']['width']}",
                new_block,
                flags=re.MULTILINE,
            )

            # 替换 active-color
            new_block = re.sub(
                r'^(\s*)active-color\s*"[^"]*"',
                rf'\1active-color "{value["border"]["color"]}"',
                new_block,
                flags=re.MULTILINE,
            )

        else:
            new_block = re.sub(
                r"^(\s*)on(\s*)$", r"\1off\2", new_block, flags=re.MULTILINE
            )

            new_block = re.sub(
                r"^(\s*)//\s*off(\s*)$", r"\1off\2", new_block, flags=re.MULTILINE
            )

            new_block = re.sub(
                r"^(\s*)//\s*on(\s*)$", r"\1off\2", new_block, flags=re.MULTILINE
            )

        updated_content = updated_content.replace(border_block, new_block)

    # ===== 修改 shadow =====
    shadow_match = re.search(r"shadow\s*\{([^}]*)\}", content, re.DOTALL)
    if shadow_match:
        shadow_block = shadow_match.group(0)
        new_block = shadow_block

        # 处理 on/off（shadow 用 on 启用）
        if value["shadow"]["enable"]:
            # 启用：取消注释 on，或把 off 改成 on
            new_block = re.sub(
                r"^(\s*)//\s*on(\s*)$", r"\1on\2", new_block, flags=re.MULTILINE
            )

            new_block = re.sub(
                r"^(\s*)off(\s*)$", r"\1on\2", new_block, flags=re.MULTILINE
            )

            new_block = re.sub(
                r"^(\s*)//\s*off(\s*)$", r"\1on\2", new_block, flags=re.MULTILINE
            )

            # 替换 softness
            new_block = re.sub(
                r"^(\s*)softness\s+\d+",
                rf"\1softness {value['shadow']['softness']}",
                new_block,
                flags=re.MULTILINE,
            )

            # 替换 spread
            new_block = re.sub(
                r"^(\s*)spread\s+\d+",
                rf"\1spread {value['shadow']['spread']}",
                new_block,
                flags=re.MULTILINE,
            )

            # 替换 offset
            new_block = re.sub(
                r"^(\s*)offset\s+x=-?\d+\s+y=-?\d+",
                rf"\1offset x={value['shadow']['offset']['x']} y={value['shadow']['offset']['y']}",
                new_block,
                flags=re.MULTILINE,
            )

            # 替换 color
            new_block = re.sub(
                r'^(\s*)color\s*"[^"]*"',
                rf'\1color "{value["shadow"]["color"]}"',
                new_block,
                flags=re.MULTILINE,
            )

        else:
            # 禁用：注释 on，或把 on 改成 off
            new_block = re.sub(
                r"^(\s*)on(\s*)$", r"\1off\2", new_block, flags=re.MULTILINE
            )

            new_block = re.sub(
                r"^(\s*)//\s*off(\s*)$", r"\1off\2", new_block, flags=re.MULTILINE
            )

            new_block = re.sub(
                r"^(\s*)//\s*on(\s*)$", r"\1off\2", new_block, flags=re.MULTILINE
            )

        updated_content = updated_content.replace(shadow_block, new_block)

    # ===== 修改 animations =====
    animations_match = re.search(r"animations\s*\{([^}]*)\}", content, re.DOTALL)
    if animations_match:
        animations_block = animations_match.group(0)
        new_block = animations_block

        # 处理 off
        if value["animations"]["enable"]:
            # 启用： off -> on
            new_block = re.sub(
                r"^(\s*)off(\s*)$", r"\1on\2", new_block, flags=re.MULTILINE
            )

            new_block = re.sub(
                r"^(\s*)//\s*off(\s*)$", r"\1on\2", new_block, flags=re.MULTILINE
            )

            new_block = re.sub(
                r"^(\s*)//\s*on(\s*)$", r"\1on\2", new_block, flags=re.MULTILINE
            )

            # 替换 slowdown
            new_block = re.sub(
                r"slowdown\s+[\d.]+",
                rf"slowdown {value['animations']['slowdown']}",
                new_block,
                flags=re.MULTILINE,
            )

        else:
            # 禁用： on -> off
            new_block = re.sub(
                r"^(\s*)on(\s*)$", r"\1off\2", new_block, flags=re.MULTILINE
            )

            new_block = re.sub(
                r"^(\s*)//\s*off(\s*)$", r"\1off\2", new_block, flags=re.MULTILINE
            )

            new_block = re.sub(
                r"^(\s*)//\s*on(\s*)$", r"\1off\2", new_block, flags=re.MULTILINE
            )

        updated_content = updated_content.replace(animations_block, new_block)

    # ===== 修改 struts =====
    struts_match = re.search(r"struts\s*\{([^}]*)\}", content, re.DOTALL)
    if struts_match:
        struts_block = struts_match.group(0)
        new_block = struts_block

        if value["struts"]["enabled"]:
            # 启用：取消注释
            new_block = re.sub(r"^(\s*)//\s*", r"\1", new_block, flags=re.MULTILINE)

            # 更新值
            if value["struts"].get("left"):
                new_block = re.sub(
                    r"^(\s*)left\s+\d+",
                    rf"\1left {value['struts']['left']}",
                    new_block,
                    flags=re.MULTILINE,
                )
            if value["struts"].get("right"):
                new_block = re.sub(
                    r"^(\s*)right\s+\d+",
                    rf"\1right {value['struts']['right']}",
                    new_block,
                    flags=re.MULTILINE,
                )
            if value["struts"].get("top"):
                new_block = re.sub(
                    r"^(\s*)top\s+\d+",
                    rf"\1top {value['struts']['top']}",
                    new_block,
                    flags=re.MULTILINE,
                )
            if value["struts"].get("bottom"):
                new_block = re.sub(
                    r"^(\s*)bottom\s+\d+",
                    rf"\1bottom {value['struts']['bottom']}",
                    new_block,
                    flags=re.MULTILINE,
                )
        else:
            # 禁用：给所有配置行添加注释
            new_block = re.sub(
                r"^(\s*)(left|right|top|bottom\s+\d+)",
                r"\1// \2",
                new_block,
                flags=re.MULTILINE,
            )

        updated_content = updated_content.replace(struts_block, new_block)

    # 写回文件
    with open(niri_file, "w", encoding="utf-8") as f:
        f.write(updated_content)

    print("niri config updated successfully")


if __name__ == "__main__":
    # 测试数据
    # test_value = {
    #     "layout": {"gaps": 20},
    #     "corner_radius": {"radius": 15},
    #     "focus-ring": {"enable": False, "width": 3, "color": "#000000"},
    #     "border": {"enable": False, "width": 6, "color": "#ffc87f"},
    #     "shadow": {
    #         "enable": False,
    #         "softness": 30,
    #         "spread": 5,
    #         "offset": {"x": 0, "y": 5},
    #         "color": "#000000",
    #     },
    #     "animations": {"enable": True, "slowdown": 1.0},
    #     "struts": {"enabled": False, "left": 64, "right": 64, "top": 64, "bottom": 64},
    # }

    args = sys.argv[1:]

    value = json.loads(args[0])

    set_niri_config(value)
