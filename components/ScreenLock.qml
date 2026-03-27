import Quickshell
import Quickshell.Wayland
import Quickshell.Io
import QtQuick

ShellRoot {
    id: root

    property bool unlock: true

    WlSessionLock {
        id: lock
        locked: root.unlock

        WlSessionLockSurface {
            LockSurface {
                width: Config.screenWidth
                height: Config.screenHeight
            }
        }
    }
}
