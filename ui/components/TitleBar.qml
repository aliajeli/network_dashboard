import QtQuick
import QtQuick.Controls
import ".." // دسترسی به Theme

Rectangle {
    id: root
    width: parent.width
    height: 40
    color: "transparent"

    property var windowRef

    // درگ کردن پنجره
    MouseArea {
        anchors.fill: parent
        property point clickPos: "0,0"
        onPressed: (mouse) => { clickPos = Qt.point(mouse.x, mouse.y) }
        onPositionChanged: (mouse) => {
            var delta = Qt.point(mouse.x - clickPos.x, mouse.y - clickPos.y)
            windowRef.x += delta.x; windowRef.y += delta.y
        }
    }

    Label {
        text: "Network Dashboard"
        anchors.centerIn: parent
        font.bold: true
        color: Theme.text_dim
    }

    Row {
        anchors.right: parent.right
        anchors.top: parent.top
        anchors.margins: 5
        spacing: 8


        Text {
            text: window.statusMessage // این متغیر را در main تعریف میکنیم
            color: Theme.accent
            font.pixelSize: 11
            anchors.left: parent.left
            anchors.leftMargin: 15
            anchors.verticalCenter: parent.verticalCenter
            visible: text !== ""
            
            // انیمیشن چشمک زن
            SequentialAnimation on opacity {
                loops: Animation.Infinite
                running: parent.visible
                NumberAnimation { to: 0.5; duration: 800 }
                NumberAnimation { to: 1.0; duration: 800 }
            }
        }
        // --- Theme Switcher Button ---
        Rectangle {
            width: 30
            height: 30
            radius: 15
            color: Theme.accent
            border.width: 1; border.color: Qt.rgba(255,255,255,0.3)
            
            Text {
                anchors.centerIn: parent
                text: "🎨"
                font.pixelSize: 14
            }

            MouseArea {
                anchors.fill: parent
                cursorShape: Qt.PointingHandCursor
                onClicked: themePopup.open()
            }

            // جایگزینی Menu با Popup کاملاً شخصی‌سازی شده
            Popup {
                id: themePopup
                y: 40
                x: -130 // تنظیم موقعیت برای باز شدن زیر دکمه
                width: 170
                height: 250 // ارتفاع تقریبی لیست
                
                modal: true
                focus: true
                closePolicy: Popup.CloseOnEscape | Popup.CloseOnPressOutside
                
                // پس‌زمینه کل لیست
                background: Rectangle {
                    color: Theme.bg_panel
                    border.color: Theme.border
                    border.width: 1
                    radius: 6
                }
                
                contentItem: ListView {
                    clip: true
                    model: ListModel {
                        ListElement { name: "Nordic (Default)"; code: "Nordic" }
                        ListElement { name: "Enterprise Light"; code: "EnterpriseLight" }
                        ListElement { name: "Enterprise Dark"; code: "EnterpriseDark" }
                        ListElement { name: "Cotton Candy"; code: "CottonCandy" }
                        ListElement { name: "Dracula"; code: "Dracula" }
                        ListElement { name: "Latte"; code: "Latte" }
                    }
                    
                    delegate: Rectangle {
                        width: 145   // کمی کمتر از عرض پاپ‌آپ
                        height: 35
                        radius: 4
                        // رنگ پس‌زمینه آیتم: اگر موس روی آن بود رنگ تم با شفافیت، اگر نه شفاف
                        color: ma.containsMouse ? Qt.rgba(Theme.primary.r, Theme.primary.g, Theme.primary.b, 0.3) : "transparent"
                        
                        // انیمیشن نرم برای تغییر رنگ
                        Behavior on color { ColorAnimation { duration: 100 } }

                        Text {
                            text: name
                            color: Theme.text_main
                            font.pixelSize: 12
                            anchors.verticalCenter: parent.verticalCenter
                            anchors.left: parent.left
                            anchors.leftMargin: 10
                        }

                        MouseArea {
                            id: ma
                            anchors.fill: parent
                            hoverEnabled: true // فعال کردن تشخیص موس
                            cursorShape: Qt.PointingHandCursor
                            onClicked: {
                                Theme.setTheme(code)
                                themePopup.close()
                            }
                        }
                    }
                }
            }
        }

        // --- Minimize ---
        Rectangle {
            width: 30; height: 30
            color: minMa.containsMouse ? Theme.warning : "transparent"
            radius: 6
            Canvas {
                anchors.centerIn: parent; width: 10; height: 10
                onPaint: { var ctx = getContext("2d")
                ctx.reset()
                ctx.strokeStyle = Theme.accent
                ctx.lineWidth = 2
                ctx.beginPath()
                ctx.moveTo(0, 5)
                ctx.lineTo(10, 5)
                ctx.stroke() }
            }
            MouseArea { id: minMa; anchors.fill: parent; hoverEnabled: true; onClicked: windowRef.showMinimized() }
        }

        // --- Close ---
        Rectangle {
            width: 30; height: 30
            color: closeMa.containsMouse ? Theme.error : "transparent"
            radius: 6
            Canvas {
                anchors.centerIn: parent; width: 10; height: 10
                onPaint: { var ctx = getContext("2d"); ctx.reset(); ctx.strokeStyle = Theme.accent; ctx.lineWidth = 2; ctx.beginPath(); ctx.moveTo(0, 0); ctx.lineTo(10, 10); ctx.moveTo(10, 0); ctx.lineTo(0, 10); ctx.stroke() }
            }
            MouseArea { id: closeMa; anchors.fill: parent; hoverEnabled: true; onClicked: windowRef.close() }
        }
    }
}