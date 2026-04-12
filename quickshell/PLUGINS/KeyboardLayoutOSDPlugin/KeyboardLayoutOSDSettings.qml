import QtQuick
import qs.Common
import qs.Widgets
import qs.Modules.Plugins

PluginSettings {
    id: root
    pluginId: "keyboardLayoutOSDPlugin"

    ToggleSetting {
        settingKey: "hideTopBarWidget"
        label: "Hide Top Bar Widget"
        description: "Hide the keyboard layout widget in the top bar (Niri only)"
        defaultValue: false
    }

    SliderSetting {
        settingKey: "osdDuration"
        label: "OSD Duration"
        description: "How long to show the keyboard layout OSD"
        defaultValue: 2000
        minimum: 500
        maximum: 5000
        unit: "ms"
    }
}
