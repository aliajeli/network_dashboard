pragma Singleton // <--- این خط خیلی مهم است

import QtQuick

QtObject {
    id: theme
    
    // --- Current Active Colors ---
    property color bg_main: "#2E3440"
    property color bg_panel: "#3B4252"
    property color bg_input: "#434C5E"
    property color text_main: "#ECEFF4"
    property color text_dim: "#D8DEE9"
    property color accent: "#88C0D0"
    property color primary: "#5E81AC"
    property color border: "transparent"
    property int radius: 8
    
    // Status Colors (Fixed or Themed)
    property color success: "#A3BE8C"
    property color error: "#BF616A"
    property color warning: "#EBCB8B"

    // --- Theme Switcher Function ---
    function setTheme(themeName) {
        if (themeName === "EnterpriseLight") {
            bg_main = "#F3F4F6"; bg_panel = "#FFFFFF"; bg_input = "#E5E7EB"
            text_main = "#1F2937"; text_dim = "#4B5563"
            accent = "#2563EB"; primary = "#3B82F6"; border = "#D1D5DB"
            radius = 6
        } 
        else if (themeName === "EnterpriseDark") {
            bg_main = "#0F172A"; bg_panel = "#1E293B"; bg_input = "#334155"
            text_main = "#F1F5F9"; text_dim = "#94A3B8"
            accent = "#38BDF8"; primary = "#0EA5E9"; border = "#334155"
            radius = 6
        }
        else if (themeName === "CottonCandy") {
            bg_main = "#FFFDF5"; bg_panel = "#FFF0F5"; bg_input = "#FDE2EC"
            text_main = "#4C1D95"; text_dim = "#8B5CF6"
            accent = "#FF69B4"; primary = "#8B5CF6"; border = "transparent"
            radius = 20
        }
        else if (themeName === "Dracula") {
            bg_main = "#282A36"; bg_panel = "#44475A"; bg_input = "#6272A4"
            text_main = "#F8F8F2"; text_dim = "#BD93F9"
            accent = "#FF79C6"; primary = "#BD93F9"; border = "#6272A4"
            radius = 8
        }
        else if (themeName === "Latte") {
            bg_main = "#EFF1F5"; bg_panel = "#E6E9EF"; bg_input = "#DCE0E8"
            text_main = "#4C4F69"; text_dim = "#6C6F85"
            accent = "#179299"; primary = "#1E66F5"; border = "transparent"
            radius = 12
        }
        else { // Nordic (Default)
            bg_main = "#2E3440"; bg_panel = "#3B4252"; bg_input = "#434C5E"
            text_main = "#ECEFF4"; text_dim = "#D8DEE9"
            accent = "#88C0D0"; primary = "#5E81AC"; border = "transparent"
            radius = 10
        }
    }
}