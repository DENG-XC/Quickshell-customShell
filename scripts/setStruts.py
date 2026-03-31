import os
import re
import sys

home = os.path.expanduser("~")
niri_file = os.path.join(home, ".config", "niri", "config.kdl")


def set_struts(left):
    with open(niri_file, "r", encoding="utf-8") as f:
        content = f.read()

    struts_match = re.search(r"struts\s*\{([^}]*)\}", content, re.DOTALL)
    if not struts_match:
        print("struts block not found")
        return False

    struts_block = struts_match.group(0)
    new_block = struts_block

    # 启用 struts（取消注释）
    new_block = re.sub(r"^(\s*)//\s*", r"\1", new_block, flags=re.MULTILINE)

    # 更新各个方向的值
    if left is not None:
        new_block = re.sub(
            r"^(\s*)left\s+\d+",
            rf"\1left {left}",
            new_block,
            flags=re.MULTILINE,
        )
        # 如果不存在 left 行，添加
        if not re.search(r"^\s*left\s+\d+", new_block, flags=re.MULTILINE):
            new_block = re.sub(
                r"(\s*struts\s*\{\s*)",
                rf"\1\n    left {left}",
                new_block,
            )

    # 替换原内容
    new_content = content.replace(struts_block, new_block)

    with open(niri_file, "w", encoding="utf-8") as f:
        f.write(new_content)

    return True


if __name__ == "__main__":
    args = sys.argv[1:]

    if len(args) >= 1:
        left = int(args[0])
        set_struts(left)
