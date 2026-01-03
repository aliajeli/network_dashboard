import QtQuick
import QtQuick.Controls
import ".." // Theme

AbstractButton {
    id: root
    // ارتفاع استاندارد و جمع‌وجور (قبلاً 32 بود)
    height: 28 
    hoverEnabled: true
    checkable: true 

    contentItem: Item {}

    background: Item {
        implicitWidth: 120
        implicitHeight: 28
        
        // کادر مربع چک‌باکس (با اندازه 18x18)
        Rectangle {
            id: indicatorBox
            width: 18; height: 18
            anchors.left: parent.left
            anchors.verticalCenter: parent.verticalCenter
            
            // در حالت عادی شفاف، اگر موس روی آن باشد کمی روشن‌تر (برای فیدبک)
            color: root.hovered ? Qt.rgba(Theme.accent.r, Theme.accent.g, Theme.accent.b, 0.1) : "transparent"
            radius: 4 
            
            // رنگ حاشیه: اگر چک شده باشد رنگ تم، اگر نه رنگ متن کم‌رنگ
            border.color: root.checked ? Theme.accent : Qt.rgba(Theme.text_main.r, Theme.text_main.g, Theme.text_main.b, 0.5)
            border.width: 1.5

            // تیک یا مربع توپر وسط
            Rectangle {
                width: 10; height: 10
                anchors.centerIn: parent
                radius: 2
                color: Theme.accent // رنگ اصلی تم
                visible: root.checked
                
                // انیمیشن کوچک برای ظاهر شدن
                scale: root.checked ? 1.0 : 0.0
                Behavior on scale { NumberAnimation { duration: 100; easing.type: Easing.OutBack } }
            }
        }

        // متن چک‌باکس
        Text {
            id: label
            text: root.text 
            font.pixelSize: 12
            // اگر موس روی چک‌باکس باشد، متن روشن‌تر شود
            color: root.hovered ? Theme.accent : Theme.text_main 
            
            opacity: root.enabled ? 1.0 : 0.5
            verticalAlignment: Text.AlignVCenter
            
            // فاصله متن از باکس
            anchors.left: indicatorBox.right
            anchors.leftMargin: 8 
            anchors.verticalCenter: parent.verticalCenter
            
            // انیمیشن تغییر رنگ متن
            Behavior on color { ColorAnimation { duration: 150 } }
        }
    }
}