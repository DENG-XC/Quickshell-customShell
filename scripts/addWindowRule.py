import os
import sys
import re
import json
import textwrap

home = os.path.expanduser("~")
niri_file = os.path.join(home, ".config", "niri", "config.kdl")


def get_window_block(content):

    block_count = []

    window_rule_match = re.finditer(r"\s*window-rule\s*\{", content)
    for match in window_rule_match:
        block_count.append(match.start())

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

def add_window_rule(width, height):
    with open(niri_file, "r", encoding="utf-8") as f:
        content = f.read()

    title_match = re.search(r"\s*match\s+title=\"clipboard\"", content)
    if title_match:
        print("Title match found, skipping insertion.")
        return

    last_block = get_window_block(content)

    if last_block:
        window_rule = textwrap.dedent(f"""\n
        // add by shell script
        window-rule {{
            match title="clipboard"
            open-floating true
            open-focused true
            default-column-width {{ fixed {width}; }}
            default-window-height {{ fixed {height}; }}
        }}""")

        new_content = content[:last_block + 1] + window_rule + content[last_block + 1:]
        print("Window rule added successfully.")
    else:
        print("No window-rule block found, cannot add rule.")
        return

    with open(niri_file, "w", encoding="utf-8") as f:
        f.write(new_content)

if __name__ == "__main__":
    args = sys.argv[1:]

    if len(args) == 2:
        width = args[0]
        height = args[1]

        add_window_rule(width, height)
