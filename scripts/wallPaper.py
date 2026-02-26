import os
import json

WALLPAPER_DIR = os.path.expanduser("~/.config/quickshell/shell/wallpaper")

IMAGE_EXTENSIONS = ('.jpg', '.jpeg', '.png', '.gif', '.bmp', '.webp', '.svg')

def get_wallpapers():

    wallpapers = []

    if not os.path.exists(WALLPAPER_DIR):
        print("wallpaper directory does not exist")
        return

    for filename in os.listdir(WALLPAPER_DIR):

        file_path = os.path.join(WALLPAPER_DIR, filename)

        if os.path.isfile(file_path) and filename.lower().endswith(IMAGE_EXTENSIONS):

            wallpaper_info = {
                "name": filename,
                "path": file_path
            }

            wallpapers.append(wallpaper_info)

    print(json.dumps(wallpapers, ensure_ascii=False))

if __name__ == "__main__":
    get_wallpapers()
