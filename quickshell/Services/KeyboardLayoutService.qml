pragma Singleton
pragma ComponentBehavior: Bound

import QtQuick
import Quickshell
import qs.Common

Singleton {
    id: root

    property string currentKeyboardLayoutDisplay: ""
    property string currentKeyboardLayoutRaw: ""
    property string currentFocusedWindowId: ""
    // Per-window layouts are handled by the KeyboardLayoutOSDPlugin if needed
    // Niri users should set track-layout: window in their niri config
    property bool perWindowLayoutsEnabled: false

    signal keyboardLayoutChanged
    signal windowFocusChanged(string windowId)

    Component.onCompleted: {
        updateCurrentLayout()
    }

    function updateCurrentLayout() {
        let layout = ""
        if (CompositorService.isNiri) {
            layout = NiriService.getCurrentKeyboardLayoutName()
        } else if (CompositorService.isDwl) {
            layout = DwlService.currentKeyboardLayout
        } else if (CompositorService.isHyprland) {
            layout = getHyprlandCurrentLayout()
        }

        if (layout && layout !== currentKeyboardLayoutRaw) {
            currentKeyboardLayoutRaw = layout
            currentKeyboardLayoutDisplay = formatLayoutName(layout)
            keyboardLayoutChanged()
        }
    }

    function formatLayoutName(layout) {
        if (!layout)
            return ""

        const parts = layout.split(" ")
        const lang = parts[0]
        const variant = parts.length > 1 ? parts.slice(1).join(" ") : ""

        const langCodes = {
            "afrikaans": "AF",
            "arabic": "AR",
            "bulgarian": "BG",
            "czech": "CZ",
            "danish": "DK",
            "german": "DE",
            "greek": "GR",
            "english": "EN",
            "spanish": "ES",
            "estonian": "EE",
            "finnish": "FI",
            "french": "FR",
            "hebrew": "HE",
            "croatian": "HR",
            "hungarian": "HU",
            "icelandic": "IS",
            "italian": "IT",
            "japanese": "JP",
            "korean": "KR",
            "lithuanian": "LT",
            "latvian": "LV",
            "dutch": "NL",
            "norwegian": "NO",
            "polish": "PL",
            "portuguese": "PT",
            "romanian": "RO",
            "russian": "RU",
            "slovak": "SK",
            "slovenian": "SL",
            "serbian": "SR",
            "swedish": "SE",
            "thai": "TH",
            "turkish": "TR",
            "ukrainian": "UA",
            "chinese": "ZH"
        }

        const code = langCodes[lang.toLowerCase()] || lang.substring(0, 2).toUpperCase()

        if (variant) {
            const variantMatch = variant.match(/\(([^)]+)\)/)
            if (variantMatch) {
                return code + " (" + variantMatch[1] + ")"
            }
        }

        return code
    }

    function getHyprlandCurrentLayout() {
        return ""
    }

    function onWindowFocused(windowId) {
        if (!perWindowLayoutsEnabled)
            return

        currentFocusedWindowId = windowId

        if (!windowId)
            return

        const savedLayout = getWindowLayout(windowId)
        if (savedLayout && savedLayout !== currentKeyboardLayoutRaw) {
            switchToLayout(savedLayout)
        }
    }

    function switchToLayout(layout) {
        if (CompositorService.isNiri) {
            const idx = NiriService.keyboardLayoutNames.indexOf(layout)
            if (idx >= 0) {
                NiriService.switchToKeyboardLayout(idx)
            }
        } else if (CompositorService.isHyprland) {
            const mainKeyboard = getHyprlandMainKeyboard()
            if (mainKeyboard) {
                const idx = HyprlandService.keyboardLayouts.indexOf(layout)
                if (idx >= 0) {
                    Quickshell.execDetached(["hyprctl", "switchxkblayout", mainKeyboard, "+" + idx])
                }
            }
        } else if (CompositorService.isDwl) {
            Quickshell.execDetached(["mmsg", "-d", "switch_keyboard_layout"])
        }
    }

    function getHyprlandMainKeyboard() {
        return ""
    }

    Connections {
        target: NiriService
        function onCurrentKeyboardLayoutIndexChanged() {
            root.updateCurrentLayout()
        }
        function onWindowsChanged() {
            if (NiriService.windows.length > 0) {
                const focused = NiriService.windows.find(w => w.is_focused)
                if (focused && focused.id !== currentFocusedWindowId) {
                    currentFocusedWindowId = focused.id
                    windowFocusChanged(focused.id)
                }
            }
        }
    }

    Connections {
        target: DwlService
        function onStateChanged() {
            Qt.callLater(root.updateCurrentLayout)
        }
    }
}
