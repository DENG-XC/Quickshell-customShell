import os
import shutil
import subprocess

import distro

home = os.path.expanduser("~")
apps = [
    "niri",
    "quickshell",
    "clipse",
    "awww",
    "hyprpicker",
    "qt6-qt5compat",
]


def install_golang(pm):
    try:
        answer = input("install weak_dependencies golang? (y/n):")
        if answer.lower() == "y":
            result = subprocess.run(["sudo", pm, "install", "-y", "golang"])
            if result.returncode == 0:
                return True
        return False
    except subprocess.CalledProcessError as e:
        print(f"{e}")
        return False


def install_rust():
    try:
        answer = input("install weak_dependencies rust? (y/n):")
        if answer.lower() == "y":
            result = subprocess.run(
                "curl --proto =https --tlsv1.2 -sSf https://sh.rustup.rs | sh",
                shell=True,
            )
            if result.returncode == 0:
                return True
        return False
    except subprocess.CalledProcessError as e:
        print(f"{e}")
        return False


def install_awww_dependencies(pm, dep):
    try:
        answer = input("install awww weak_dependencies? (y/n):")
        if answer.lower() == "y":
            result = subprocess.run(["sudo", pm, "install", "-y", dep])
            if result.returncode == 0:
                return True
        return False
    except subprocess.CalledProcessError as e:
        print(f"{e}")
        return False


def check_dependencies(pm, app):
    try:
        result = subprocess.run(["which", app], capture_output=True)
        if result.returncode == 0:
            return True
        check = subprocess.run([pm, "list", "--installed", app], capture_output=True)
        return check.returncode == 0
    except subprocess.CalledProcessError as e:
        print(f"{e}")
        return False


def check_distro():
    if distro.id().lower() == "fedora":
        return "dnf"
    else:
        return False


def install_dependencies(missing_list, pm):

    answer = input(f"install {missing_list}? (y/n):")
    if answer.lower() == "y":
        original_dir = os.getcwd()
        src_dir = os.path.join(home, ".local")

        os.chdir(src_dir)

        for package in missing_list:
            if package == "niri":
                try:
                    result = subprocess.run([f"{pm} copr list | grep niri"], shell=True, capture_output=True)
                    if result.returncode != 0:
                        print("enable yalter/niri copr")
                        subprocess.run(
                            ["sudo", pm, "copr", "enable", "-y", "yalter/niri"],
                            check=True,
                        )

                    else:
                        print("niri copr already enabled")

                    print(f"installing {package}")
                    subprocess.run(["sudo", pm, "install", "-y", "niri"], check=True)

                except subprocess.CalledProcessError as e:
                    print(f"Failed to install {package}: {e}")

            elif package == "qt6-qt5compat":
                try:
                    print(f"installing {package}")
                    subprocess.run(
                        ["sudo", pm, "install", "-y", "qt6-qt5compat"], check=True
                    )

                except subprocess.CalledProcessError as e:
                    print(f"Failed to install {package}: {e}")

            elif package == "quickshell":
                try:
                    result = subprocess.run([f"{pm} copr list | grep quickshell"], shell=True, capture_output=True)
                    if result.returncode != 0:
                        print("enable errornointernet/quickshell copr")
                        subprocess.run(
                            [
                                "sudo",
                                pm,
                                "copr",
                                "enable",
                                "-y",
                                "errornointernet/quickshell",
                            ],
                            check=True,
                        )
                    else:
                        print("quickshell copr already enabled")

                    print(f"installing {package}")
                    subprocess.run(
                        ["sudo", pm, "install", "-y", "quickshell"], check=True
                    )

                except subprocess.CalledProcessError as e:
                    print(f"Failed to install {package}: {e}")

            elif package == "clipse":
                try:
                    package_dir = os.path.join(src_dir, "clipse")
                    if os.path.exists(package_dir):
                        print(f"{package} directory already exists, skipping clone")
                    else:
                        print(f"Cloning {package} into {src_dir}")
                        subprocess.run(
                            ["git", "clone", "https://github.com/savedra1/clipse"],
                            check=True,
                        )

                    os.chdir("clipse")

                    # 检查二进制文件是否已存在
                    bin_dir = os.path.expanduser("~/.local/bin")
                    bin_path = os.path.join(bin_dir, "clipse")
                    if os.path.exists(bin_path):
                        print(
                            f"{package} binary already exists in ~/.local/bin, skipping build"
                        )
                    else:
                        try:
                            print(f"Building {package}")
                            subprocess.run(["go", "mod", "tidy"], check=True)
                            subprocess.run(["make", "wayland"], check=True)
                        except subprocess.CalledProcessError as e:
                            print(f"Failed to build {package}: {e}")
                            print("Please fix the build error and run the script again")
                            return False

                        print(f"Build success {package}, moving to ~/.local/bin")
                        os.makedirs(bin_dir, exist_ok=True)
                        subprocess.run(["cp", "clipse", bin_dir], check=True)

                    os.chdir(src_dir)

                except subprocess.CalledProcessError as e:
                    print(f"Failed to install {package}: {e}")

            elif package == "hyprpicker":
                try:
                    result = subprocess.run([f"{pm} copr list | grep hyprland"], shell=True, capture_output=True)
                    if result.returncode != 0:
                        print("enable solopasha/hyprland copr")
                        subprocess.run(
                            [
                                "sudo",
                                pm,
                                "copr",
                                "enable",
                                "-y",
                                "solopasha/hyprland",
                            ],
                            check=True,
                        )
                    else:
                        print("hyprpicker copr already enabled")

                    print(f"installing {package}")
                    subprocess.run(
                        ["sudo", pm, "install", "-y", "hyprpicker"], check=True
                    )

                except subprocess.CalledProcessError as e:
                    print(f"Failed to install {package}: {e}")

            elif package == "awww":
                try:
                    package_dir = os.path.join(src_dir, "awww")
                    if os.path.exists(package_dir):
                        print(f"{package} directory already exists, skipping clone")
                    else:
                        print(f"Cloning {package} into {src_dir}")
                        subprocess.run(
                            ["git", "clone", "https://codeberg.org/LGFae/awww.git"],
                            check=True,
                        )

                    os.chdir("awww")

                    bin_dir = os.path.expanduser("~/.local/bin")
                    aww_path = os.path.join(bin_dir, "awww")
                    aww_daemon_path = os.path.join(bin_dir, "awww-daemon")
                    if os.path.exists(aww_path) and os.path.exists(aww_daemon_path):
                        print(
                            f"{package} binaries already exist in ~/.local/bin, skipping build"
                        )
                    else:
                        try:
                            print(f"Building {package}")
                            subprocess.run(["cargo", "build", "--release"], check=True)
                        except subprocess.CalledProcessError as e:
                            print(f"Failed to build {package}: {e}")
                            print("Please fix the build error and run the script again")
                            return False

                        print(f"Build success {package}, moving to ~/.local/bin")
                        os.makedirs(bin_dir, exist_ok=True)
                        subprocess.run(
                            ["cp", "target/release/awww", bin_dir], check=True
                        )
                        subprocess.run(
                            ["cp", "target/release/awww-daemon", bin_dir],
                            check=True,
                        )

                    os.chdir(src_dir)

                except subprocess.CalledProcessError as e:
                    print(f"Failed to install {package}: {e}")

        os.chdir(original_dir)
        return True

    else:
        print("skipped, please install dependencies manually")
        return False


def copy_shell():
    script_dir = os.path.dirname(os.path.abspath(__file__))
    target_dir = os.path.join(home, ".config", "quickshell")

    if os.path.abspath(script_dir) == os.path.abspath(target_dir):
        print("Shell files are already in ~/.config/quickshell, skipping copy.")

    else:
        ignore_patterns = shutil.ignore_patterns("install.py", ".git", "__pycache__", "*.pyc")
        shutil.copytree(
            script_dir, target_dir, dirs_exist_ok=True, ignore=ignore_patterns
        )
        print("Shell files copied successfully.")

def check_weak_dependencies(pm):
    weak_dependencies = [
        "cargo",
        "go",
    ]
    missing_weak = []
    for app in weak_dependencies:
        result = subprocess.run(["which", app], capture_output=True)
        if result.returncode != 0:
            check = subprocess.run(
                [pm, "list", "--installed", app], capture_output=True
            )
            if check.returncode == 0:
                continue
            else:
                missing_weak.append(app)

    return missing_weak


def main():
    distro_package_manager = check_distro()
    missing = []
    install_success = False
    awww_dependencies = [
        "lz4-devel",
        "wayland-protocols-devel",
        "wayland-devel",
    ]

    for app in apps:
        if check_dependencies(distro_package_manager, app):
            print(f"{app} is installed.")
        else:
            print(f"{app} is not installed.")
            if check_distro():
                missing.append(app)
            else:
                print("can't find package manager, try to install it manually")

    if missing:
        missing_weak = check_weak_dependencies(distro_package_manager)

        if "awww" in missing and "cargo" in missing_weak:
            for dep in awww_dependencies:
                if not install_awww_dependencies(distro_package_manager, dep):
                    print(
                        f"failed to install awww_dependencies {dep}, skipping installation, please install it manually."
                    )
                    return
            if not install_rust():
                missing.remove("awww")
                print(
                    "failed to install rust, skipping awww installation, please install it manually."
                )
            else:
                print(
                    "rust installed successfully, need to restart shell and run install script again."
                )
                return

        if "clipse" in missing and "go" in missing_weak:
            if not install_golang(distro_package_manager):
                missing.remove("clipse")
                print(
                    "failed to install golang, skipping clipse installation, please install it manually."
                )

        if missing:
            install_success = install_dependencies(missing, distro_package_manager)

    if not missing:
        copy_shell()

    elif install_success:
        copy_shell()


if __name__ == "__main__":
    main()
