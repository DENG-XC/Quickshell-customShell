import os
import sys
import re
import json
import textwrap

home = os.path.expanduser("~")
niri_file = os.path.join(home, ".config", "niri", "config.kdl")


def get_window_block(content):
    """找到最后一个 window-rule 块的结束位置"""

    block_count = []

    window_rule_match = re.finditer(r"\s*window-rule\s*\{", content)
    for match in window_rule_match:
        block_count.append(match.start())

    if not block_count:
        return None  # 没找到任何 window-rule

    last_block = block_count[-1]

    brace_count = 0
    position = last_block

    while position < len(content):
        char = content[position]
        if char == "{":
            brace_count += 1
        elif char == "}":
            brace_count -= 1
            if brace_count == 0:
                return position
        position += 1

    return None  # 没找到结束位置

def add_window_rule(data):
    # 解析 JSON 数据
    try:
        data = json.loads(data)
    except json.JSONDecodeError:
        print("Invalid JSON data")
        return

    with open(niri_file, "r", encoding="utf-8") as f:
        content = f.read()

    # 处理 clipboard window-rule
    title_match = re.search(r"\s*match\s+title=\"clipboard\"", content)
    if title_match:
        position = title_match.start()
        start = title_match.start()
        brace_count = 1
        end = None

        while position < len(content):
            char = content[position]
            if char == "{":
                brace_count += 1
            elif char == "}":
                brace_count -= 1
                if brace_count == 0:
                    end = position
                    break
            position += 1

        if end:
            clipboard_content = content[start:end + 1]

            width_match = re.search(r"\s*default-column-width\s+\{\s+fixed\s+(\d+)\;\s+\}", clipboard_content)
            height_match = re.search(r"\s*default-window-height\s+\{\s+fixed\s+(\d+)\;\s+\}", clipboard_content)

            if width_match:
                clipboard_width = width_match.group(1)
                width = data["clipboard"]["width"]
                if width != clipboard_width:
                    clipboard_content = re.sub(r"default-column-width\s+\{\s+fixed\s+\d+\;\s+\}", f"default-column-width {{ fixed {width}; }}", clipboard_content)

            if height_match:
                clipboard_height = height_match.group(1)
                height = data["clipboard"]["height"]
                if height != clipboard_height:
                    clipboard_content = re.sub(r"default-window-height\s+\{\s+fixed\s+\d+\;\s+\}", f"default-window-height {{ fixed {height}; }}", clipboard_content)

            content = content[:start] + clipboard_content + content[end + 1:]
            print("Clipboard window rule updated.")

    if not title_match:
        last_block = get_window_block(content)

        if last_block:
            width = data["clipboard"]["width"]
            height = data["clipboard"]["height"]

            window_rule = textwrap.dedent(f"""\n
            // add by shell script
            window-rule {{
                match title="clipboard"
                open-floating true
                open-focused true
                default-column-width {{ fixed {width}; }}
                default-window-height {{ fixed {height}; }}
            }}""")

            content = content[:last_block + 1] + window_rule + content[last_block + 1:]
            print("Clipboard window rule added.")
        else:
            print("No window-rule block found, cannot add clipboard rule.")
            return

    # 处理 settings window-rule（使用更新后的 content）
    title_match = re.search(r"\s*match\s+title=\"settings\"", content)
    if title_match:
        position = title_match.start()
        start = title_match.start()
        brace_count = 1
        end = None

        while position < len(content):
            char = content[position]
            if char == "{":
                brace_count += 1
            elif char == "}":
                brace_count -= 1
                if brace_count == 0:
                    end = position
                    break
            position += 1

        if end:
            settings_content = content[start:end + 1]

            width_match = re.search(r"\s*default-column-width\s+\{\s+fixed\s+(\d+)\;\s+\}", settings_content)
            height_match = re.search(r"\s*default-window-height\s+\{\s+fixed\s+(\d+)\;\s+\}", settings_content)

            if width_match:
                settings_width = width_match.group(1)
                width = data["settings"]["width"]
                if width != settings_width:
                    settings_content = re.sub(r"default-column-width\s+\{\s+fixed\s+\d+\;\s+\}", f"default-column-width {{ fixed {width}; }}", settings_content)

            if height_match:
                settings_height = height_match.group(1)
                height = data["settings"]["height"]
                if height != settings_height:
                    settings_content = re.sub(r"default-window-height\s+\{\s+fixed\s+\d+\;\s+\}", f"default-window-height {{ fixed {height}; }}", settings_content)

            content = content[:start] + settings_content + content[end + 1:]
            print("Settings window rule updated.")

    if not title_match:
        last_block = get_window_block(content)

        if last_block:
            width = data["settings"]["width"]
            height = data["settings"]["height"]

            window_rule = textwrap.dedent(f"""\n
            // add by shell script
            window-rule {{
                match title="settings"
                open-floating true
                open-focused true
                default-column-width {{ fixed {width}; }}
                default-window-height {{ fixed {height}; }}
            }}""")

            content = content[:last_block + 1] + window_rule + content[last_block + 1:]
            print("Settings window rule added.")
        else:
            print("No window-rule block found, cannot add settings rule.")
            return

    # 最后写入文件
    with open(niri_file, "w", encoding="utf-8") as f:
        f.write(content)

if __name__ == "__main__":
    args = sys.argv[1:]

    if len(args) == 1:
        data = args[0]
        add_window_rule(data)
