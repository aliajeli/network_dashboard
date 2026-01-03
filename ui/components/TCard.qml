import QtQuick
import ".." // Theme

Rectangle {
    color: Theme.bg_panel
    radius: Theme.radius
    border.color: Theme.border
    border.width: Theme.border === "transparent" ? 0 : 1
    
    Behavior on color { ColorAnimation { duration: 200 } }
}