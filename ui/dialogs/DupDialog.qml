import QtQuick
import QtQuick.Controls
import "../components"

Dialog { 
    id: root
    x: (parent.width - width)/2; y: (parent.height - height)/2
    width: 300; height: 160
    modal: true; closePolicy: Popup.NoAutoClose
    
    property string dupName: ""
    property string dupType: ""
    property var onOkClicked 

    property color c_panel: "#3b4252"
    property color c_orange: "#d08770"
    property color c_text: "#eceff4"
    property color c_primary: "#5e81ac"

    background: Rectangle { color: c_panel; radius: 8; border.color: c_orange; border.width: 1 }
    
    Column { 
        anchors.centerIn: parent; spacing: 15
        Label { text: "⚠️ Duplicate Found!"; color: c_orange; font.bold: true; font.pixelSize: 14; anchors.horizontalCenter: parent.horizontalCenter } 
        Label { text: "The " + root.dupType.toLowerCase() + " '" + root.dupName + "'\nis already in the list."; color: c_text; font.pixelSize: 12; horizontalAlignment: Text.AlignHCenter; anchors.horizontalCenter: parent.horizontalCenter } 
        TButton { 
            text: "OK"; width: 80; btnColor: c_primary
            onClicked: { root.close(); if(onOkClicked) onOkClicked(root.dupType === "Folder") } 
            anchors.horizontalCenter: parent.horizontalCenter 
        } 
    } 
}