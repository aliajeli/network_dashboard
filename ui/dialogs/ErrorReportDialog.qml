import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import "../components"

Dialog { 
    id: root
    x: (parent.width - width)/2; y: (parent.height - height)/2
    width: 600; height: 400
    modal: true
    
    property var model 

    property color c_panel: "#3b4252"
    property color c_input: "#434c5e"
    property color c_red: "#bf616a"
    property color c_text: "#eceff4"
    property color c_text_dim: "#d8dee9"
    property color c_primary: "#5e81ac"

    background: Rectangle { color: c_panel; radius: 10; border.color: c_red; border.width: 1 }
    
    ColumnLayout { 
        anchors.fill: parent; anchors.margins: 15; spacing: 10
        Label { text: "Operation Completed with Errors"; color: c_red; font.bold: true; font.pixelSize: 16; Layout.alignment: Qt.AlignHCenter } 
        Rectangle { 
            Layout.fillWidth: true; Layout.fillHeight: true; color: c_input; radius: 5; clip: true
            ListView { 
                id: errorList
                anchors.fill: parent; anchors.margins: 5; spacing: 5; model: root.model
                delegate: Rectangle { 
                    // FIX: استفاده از ID لیست برای عرض
                    width: errorList.width
                    height: 40; color: c_panel; radius: 4
                    RowLayout { 
                        anchors.fill: parent; anchors.leftMargin: 10; anchors.rightMargin: 10
                        Label { text: "❌"; color: c_red; font.pixelSize: 14 } 
                        Column { 
                            Layout.fillWidth: true
                            Label { text: model.name + " (" + model.ip + ")"; color: c_text; font.bold: true; font.pixelSize: 12 } 
                            Label { text: model.reason; color: c_text_dim; font.pixelSize: 11; elide: Text.ElideRight } 
                        } 
                    } 
                } 
            } 
        } 
        TButton { text: "Close"; width: 100; btnColor: c_primary; onClicked: root.close(); Layout.alignment: Qt.AlignRight } 
    } 
}