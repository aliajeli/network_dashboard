import QtQuick
import QtQuick.Controls
import ".." // Theme

Button {
    id: control
    // اگر رنگ خاصی ندادیم، از رنگ اصلی تم استفاده کن
    property color btnColor: Theme.primary 
    property color textColor: Theme.text_main
    
    height: 32; hoverEnabled: true

    contentItem: Text {
        text: control.text
        font.pixelSize: 12
        opacity: enabled ? 1.0 : 0.3
        color: textColor
        horizontalAlignment: Text.AlignHCenter
        verticalAlignment: Text.AlignVCenter
        elide: Text.ElideRight
    }

    background: Rectangle {
        implicitWidth: 100; implicitHeight: 32
        radius: Theme.radius
        color: control.down ? Qt.darker(control.btnColor, 1.2) : control.btnColor
        
        // انیمیشن نرم تغییر رنگ
        Behavior on color { ColorAnimation { duration: 150 } }
    }
}