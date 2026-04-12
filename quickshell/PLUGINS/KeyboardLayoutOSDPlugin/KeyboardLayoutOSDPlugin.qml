import QtQuick
import Quickshell
import qs.Common
import qs.Services
import qs.Widgets
import qs.Modules.Plugins

PluginComponent {
    id: root

    property int osdDuration: pluginData?.osdDuration !== undefined ? pluginData.osdDuration : 2000
    property string lastLayout: ""
    property var osdInstances: []

    Component {
        id: osdComponent

        DankOSD {
            modelData: screen  // DankOSD uses modelData to set its screen internally
            osdWidth: Theme.iconSize + Theme.spacingS * 4 + 80
            osdHeight: Theme.iconSize + Theme.spacingS * 2
            autoHideInterval: root.osdDuration
            enableMouseInteraction: false

            content: Item {
                anchors.fill: parent

                Row {
                    anchors.centerIn: parent
                    spacing: Theme.spacingS

                    DankIcon {
                        name: "keyboard"
                        size: Theme.iconSize
                        color: Theme.primary
                    }

                    StyledText {
                        text: KeyboardLayoutService.currentKeyboardLayoutDisplay || ""
                        font.pixelSize: Theme.fontSizeMedium
                        color: Theme.surfaceText
                        anchors.verticalCenter: parent.verticalCenter
                    }
                }
            }
        }
    }

    Connections {
        target: KeyboardLayoutService

        function onKeyboardLayoutChanged() {
            if (KeyboardLayoutService.currentKeyboardLayoutDisplay !== root.lastLayout) {
                root.lastLayout = KeyboardLayoutService.currentKeyboardLayoutDisplay
                showOSD()
            }
        }

        function onWindowFocusChanged(windowId) {
            // Delay slightly to let Niri's per-window layout update complete
            Qt.callLater(() => {
                root.lastLayout = KeyboardLayoutService.currentKeyboardLayoutDisplay
                showOSD()
            })
        }
    }

    Connections {
        target: Quickshell

        function onScreensChanged() {
            recreateOSDs()
        }
    }

    function recreateOSDs() {
        // Destroy existing OSDs
        osdInstances.forEach(osd => osd.destroy())
        osdInstances = []

        // Create new OSDs for each screen
        Quickshell.screens.forEach(screen => {
            let osd = osdComponent.createObject(root, { modelData: screen })
            if (osd) {
                osdInstances.push(osd)
            }
        })
    }

    function showOSD() {
        osdInstances.forEach(osd => {
            if (osd && typeof osd.show === "function") {
                osd.show()
            }
        })
    }

    Component.onCompleted: {
        console.info("KeyboardLayoutOSDPlugin: Started")
        recreateOSDs()
    }

    Component.onDestruction: {
        console.info("KeyboardLayoutOSDPlugin: Stopped")
        osdInstances.forEach(osd => osd.destroy())
    }
}
