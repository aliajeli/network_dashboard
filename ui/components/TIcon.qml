import QtQuick
import ".." // برای دسترسی به Theme

Canvas { 
    id: root
    
    // نوع آیکون (File, Folder, Drive, etc.)
    property string iconType: "File"
    
    // رنگ آیکون (اگر مقداردهی نشود، از رنگ‌های پیش‌فرض تم استفاده می‌کند)
    property color iconColor: Theme.text_main 
    
    // رنگ پنل (برای بخش‌هایی از آیکون که نیاز به پس‌زمینه دارند)
    property color panelColor: Theme.bg_panel 

    width: 20; height: 20
    
    onPaint: { 
        var ctx = getContext("2d"); ctx.reset(); 
        ctx.fillStyle = iconColor; 
        
        if (iconType === "Folder") { 
            ctx.beginPath(); ctx.moveTo(2, 4); ctx.lineTo(8, 4); ctx.lineTo(10, 6); ctx.lineTo(18, 6); ctx.lineTo(18, 16); ctx.lineTo(2, 16); ctx.closePath(); ctx.fill(); 
        } 
        else if (iconType === "File") { 
            ctx.beginPath(); ctx.moveTo(4, 2); ctx.lineTo(12, 2); ctx.lineTo(16, 6); ctx.lineTo(16, 18); ctx.lineTo(4, 18); ctx.closePath(); ctx.fill(); 
            ctx.fillStyle = panelColor; ctx.beginPath(); ctx.moveTo(12, 2); ctx.lineTo(12, 6); ctx.lineTo(16, 6); ctx.fill(); 
        } 
        else if (iconType === "Parent" || iconType === "Up") { 
            ctx.beginPath(); ctx.moveTo(10, 4); ctx.lineTo(4, 10); ctx.lineTo(7, 10); ctx.lineTo(7, 16); ctx.lineTo(13, 16); ctx.lineTo(13, 10); ctx.lineTo(16, 10); ctx.closePath(); ctx.fill(); 
        } 
        else if (iconType === "Drive") { 
            ctx.beginPath(); 
            // رسم مستطیل گرد برای درایو
            ctx.roundedRect(2, 6, 16, 8, 2, 2); 
            ctx.fill(); 
            ctx.fillStyle = panelColor; ctx.beginPath(); ctx.arc(14, 10, 1, 0, 2*Math.PI); ctx.fill(); 
        } 
        else if (iconType === "Desktop") { 
            ctx.beginPath(); ctx.rect(2, 3, 16, 10); ctx.moveTo(8, 16); ctx.lineTo(12, 16); ctx.lineTo(12, 13); ctx.lineTo(8, 13); ctx.closePath(); ctx.fill(); 
        } 
        else if (iconType === "Close") { 
            ctx.strokeStyle = iconColor; ctx.lineWidth = 3; ctx.beginPath(); ctx.moveTo(5, 5); ctx.lineTo(15, 15); ctx.moveTo(15, 5); ctx.lineTo(5, 15); ctx.stroke(); 
        } 
    } 
    
    // وقتی تم عوض شد، آیکون دوباره رسم شود
    onIconColorChanged: requestPaint()
    onPanelColorChanged: requestPaint()
}