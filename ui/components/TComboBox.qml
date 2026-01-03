import QtQuick
import QtQuick.Controls
import ".." // Theme

ComboBox { 
    id: control
    height: 32
    hoverEnabled: true
    
    // پراپرتی‌های رنگی
    property color c_text: Theme.text_main
    property color c_bg: Theme.bg_input
    property color c_panel: Theme.bg_panel
    property color c_accent: Theme.accent

    // آیتم‌های لیست بازشونده
    delegate: ItemDelegate { 
        width: control.width
        contentItem: Text { 
            text: modelData
            color: control.c_text
            font.pixelSize: 12
            elide: Text.ElideRight
            verticalAlignment: Text.AlignVCenter 
        } 
        background: Rectangle { 
            color: highlighted ? Theme.primary : control.c_panel 
            radius: Theme.radius
        } 
        highlighted: control.highlightedIndex === index 
    } 

    // فلش کوچک سمت راست
    indicator: Canvas { 
        x: control.width - width - control.rightPadding
        y: control.topPadding + (control.availableHeight - height) / 2
        width: 12
        height: 8
        
        onPaint: { 
            var ctx = getContext("2d")
            ctx.reset()
            ctx.moveTo(0, 0)
            ctx.lineTo(width, 0)
            ctx.lineTo(width / 2, height)
            ctx.closePath()
            ctx.fillStyle = control.c_text
            ctx.fill()
        } 
    } 

    // متنی که الان انتخاب شده
    contentItem: Text { 
        leftPadding: 10
        rightPadding: 12 + control.spacing
        text: control.displayText
        font.pixelSize: 12
        color: control.c_text
        verticalAlignment: Text.AlignVCenter
        elide: Text.ElideRight 
    } 

    // پس‌زمینه اصلی کمبوباکس
    background: Rectangle { 
        implicitWidth: 120
        implicitHeight: 32
        color: control.c_bg
        radius: Theme.radius
        border.color: control.activeFocus ? control.c_accent : Theme.border
        // اگر رنگ شفاف بود، عرض بوردر 0 شود
        border.width: Theme.border == "transparent" ? 0 : 1
    } 

    // منوی بازشونده (Popup)
    popup: Popup { 
        y: control.height - 1
        width: control.width
        implicitHeight: contentItem.implicitHeight
        padding: 4
        
        contentItem: ListView { 
            clip: true
            implicitHeight: contentHeight
            model: control.popup.visible ? control.delegateModel : null
            currentIndex: control.highlightedIndex
            ScrollIndicator.vertical: ScrollIndicator { } 
        } 
        
        background: Rectangle { 
            color: control.c_panel
            border.color: Theme.border
            radius: Theme.radius
        } 
    } 
}