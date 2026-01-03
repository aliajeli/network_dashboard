import QtQuick
import QtQuick.Controls
import ".." // Theme

TextField {
    id: control
    height: 32; verticalAlignment: Text.AlignVCenter
    
    color: Theme.text_main
    selectionColor: Theme.accent
    selectedTextColor: Theme.bg_main
    font.pixelSize: 12
    placeholderTextColor: Qt.rgba(Theme.text_dim.r, Theme.text_dim.g, Theme.text_dim.b, 0.5)

    background: Rectangle {
        color: Theme.bg_input
        radius: Theme.radius
        border.color: control.activeFocus ? Theme.accent : Theme.border
        border.width: 1
    }
}