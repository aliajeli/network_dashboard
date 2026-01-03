import QtQuick
import QtQuick.Controls
import "../components"

Dialog {
    id: root
    x: (parent.width - width)/2; y: (parent.height - height)/2
    width: 400; height: 350
    modal: true; closePolicy: Popup.CloseOnEscape
    
    property color c_panel: "#3b4252"
    property color c_accent: "#88c0d0"
    property color c_red: "#bf616a"
    property color c_text: "#eceff4"
    property color c_text_dim: "#d8dee9"
    property color c_green: "#a3be8c"
    property color c_comment: "#4c566a"

    background: Rectangle { color: c_panel; radius: 10; border.color: c_accent; border.width: 1 }
    header: Rectangle {
        width: parent.width; height: 40; color: "transparent"
        Label { text: "About Network Dashboard"; font.bold: true; color: c_accent; anchors.centerIn: parent; font.pixelSize: 14 }
        Rectangle {
            width: 30; height: 30; anchors.right: parent.right; anchors.top: parent.top; anchors.margins: 5; radius: 5
            color: aboutCloseMa.containsMouse ? c_red : "transparent"
            Canvas { anchors.centerIn: parent; width: 10; height: 10; onPaint: { var ctx = getContext("2d"); ctx.reset(); ctx.strokeStyle = c_text; ctx.lineWidth = 2; ctx.beginPath(); ctx.moveTo(0,0); ctx.lineTo(10,10); ctx.moveTo(10,0); ctx.lineTo(0,10); ctx.stroke() } }
            MouseArea { id: aboutCloseMa; anchors.fill: parent; hoverEnabled: true; onClicked: root.close() }
        }
    }
    contentItem: Column {
        spacing: 20; padding: 20; width: parent.width
        Column {
            spacing: 8; width: parent.width
            Label { text: "Technologies Used:"; color: c_text_dim; font.bold: true; font.pixelSize: 13 }
            Repeater {
                model: ["Python 3 (Backend Logic)", "PyQt6 (GUI Framework)", "QML (User Interface)", "SQLite (Database)", "Nord Theme (Color Palette)"]
                delegate: Row {
                    spacing: 10
                    Rectangle { width: 6; height: 6; radius: 3; color: c_green; anchors.verticalCenter: parent.verticalCenter }
                    Label { text: modelData; color: c_text; font.pixelSize: 12 }
                }
            }
        }
        Rectangle { width: parent.width - 40; height: 1; color: c_comment; anchors.horizontalCenter: parent.horizontalCenter }
        Column {
            spacing: 5; width: parent.width
            Label { text: "Developed by:"; color: c_text_dim; font.pixelSize: 11; anchors.horizontalCenter: parent.horizontalCenter }
            Label { text: "Ali Ajeli Lahiji"; color: c_accent; font.bold: true; font.pixelSize: 14; anchors.horizontalCenter: parent.horizontalCenter }
            Label { text: "Lahiji.ali@hyperfamili.com"; color: c_text_dim; font.pixelSize: 12; anchors.horizontalCenter: parent.horizontalCenter }
        }
    }
}