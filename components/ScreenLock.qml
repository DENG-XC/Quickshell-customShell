import Quickshell
import Quickshell.Wayland
import Quickshell.Io
import QtQuick

ShellRoot {
    id: root

    property string userName: ""
    property bool unlock: true

    Process {
        id: currentwsproc
        command: ["whoami"]
        running: true
        stdout: StdioCollector {
            onStreamFinished: {
                root.userName = this.text;
            }
        }
    }

    WlSessionLock {
        id: lock
        locked: root.unlock

        WlSessionLockSurface {
            LockSurface {
                width: Screen.width
                height: Screen.height
            }
        }
    }
}
