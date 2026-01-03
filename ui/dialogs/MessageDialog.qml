import QtQuick
import QtQuick.Controls
import "../components"

Dialog { 
    id: root
    x: (parent.width - width)/2; y: (parent.height - height)/2
    width: 350; height: 180
    modal: true
    
    property string msg: ""
    property bool isError: false
    
    property color c_panel: "#3b4252"
    property color c_green: "#a3be8c"
    property color c_orange: "#d08770"
    property color c_text: "#eceff4"
    property color c_primary: "#5e81ac"

    background: Rectangle { color: c_panel; radius: 8; border.color: root.isError ? c_orange : c_green; border.width: 1 }
    
    Column { 
        anchors.centerIn: parent; spacing: 15; width: parent.width - 40
        Label { text: root.isError ? "⚠️ Attention" : "✅ Success"; color: root.isError ? c_orange : c_green; font.bold: true; font.pixelSize: 16; anchors.horizontalCenter: parent.horizontalCenter } 
        Label { text: root.msg; color: c_text; font.pixelSize: 12; horizontalAlignment: Text.AlignHCenter; wrapMode: Text.Wrap; width: parent.width } 
        TButton { text: "OK"; width: 80; btnColor: c_primary; onClicked: root.close(); anchors.horizontalCenter: parent.horizontalCenter } 
    } 
}