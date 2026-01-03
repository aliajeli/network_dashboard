import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import "../components"

Dialog { 
    id: root
    x: (parent.width - width)/2; y: (parent.height - height)/2
    width: 700; height: 400
    modal: true; closePolicy: Popup.CloseOnEscape
    
    property bool browseFolderMode: false
    property string currentBrowsePath: ""
    property var quickAccessModel
    property var dirModel
    
    property var onRefreshDir
    property var onAddSelected

    property color c_panel: "#3b4252"
    property color c_input: "#434c5e"
    property color c_accent: "#88c0d0"
    property color c_text: "#eceff4"
    property color c_red: "#bf616a"
    property color c_green: "#a3be8c"
    property color c_orange: "#d08770"

    background: Rectangle { color: c_panel; radius: 10; border.color: c_accent; border.width: 1 }
    
    ColumnLayout { 
        anchors.fill: parent; anchors.margins: 10; spacing: 10
        Label { text: root.browseFolderMode ? "Select Folder(s)" : "Select File(s)"; color: c_accent; font.bold: true; font.pixelSize: 14; Layout.alignment: Qt.AlignHCenter } 
        TInput { text: root.currentBrowsePath; Layout.fillWidth: true; readOnly: true }
        
        RowLayout { 
            Layout.fillWidth: true; Layout.fillHeight: true; spacing: 10
            
            // --- Quick Access List ---
            Rectangle { 
                Layout.fillHeight: true; Layout.preferredWidth: 150; color: c_input; radius: 4; clip: true
                ListView { 
                    id: quickList
                    anchors.fill: parent; anchors.margins: 2; model: root.quickAccessModel; spacing: 2
                    delegate: Rectangle { 
                        // FIX: Use ListView.view.width instead of parent.width
                        width: ListView.view.width 
                        height: 26; color: "transparent"
                        RowLayout { 
                            anchors.fill: parent; anchors.leftMargin: 5
                            TIcon { iconType: model.iconType; iconColor: c_accent; panelColor: c_panel } 
                            Label { text: model.name; color: c_text; font.pixelSize: 11; elide: Text.ElideRight; Layout.fillWidth: true } 
                        } 
                        MouseArea { anchors.fill: parent; onClicked: if(onRefreshDir) onRefreshDir(model.path) } 
                    } 
                } 
            }

            // --- Directory List ---
            Rectangle { 
                Layout.fillWidth: true; Layout.fillHeight: true; color: c_input; radius: 4
                ListView { 
                    id: fileList
                    anchors.fill: parent; anchors.margins: 5; clip: true; model: root.dirModel
                    delegate: Rectangle { 
                        // FIX: Use ListView.view.width instead of parent.width
                        width: ListView.view.width 
                        height: 30; color: "transparent"
                        RowLayout { 
                            anchors.fill: parent; spacing: 5
                            TCheck { visible: model.type !== "Parent" && (root.browseFolderMode ? model.type === "Folder" : model.type === "File"); checked: model.checked; onClicked: model.checked = checked }
                            Item { 
                                Layout.fillWidth: true; Layout.fillHeight: true
                                RowLayout { 
                                    anchors.fill: parent
                                    TIcon { iconType: model.type === "Parent" ? "Up" : model.type; iconColor: model.type === "Folder" ? c_orange : (model.type === "Parent" ? c_accent : c_text) } 
                                    Label { text: model.name; color: c_text; font.pixelSize: 12; Layout.fillWidth: true; elide: Text.ElideRight } 
                                } 
                                MouseArea { anchors.fill: parent; onClicked: { if (model.type === "Folder" || model.type === "Parent") { if(onRefreshDir) onRefreshDir(model.path) } else if (model.type === "File" && !root.browseFolderMode) model.checked = !model.checked } } 
                            } 
                        } 
                    } 
                } 
            } 
        }
        Row { 
            Layout.alignment: Qt.AlignRight; spacing: 10
            TButton { text: "Cancel"; btnColor: c_red; onClicked: root.close() } 
            TButton { text: "Add Selected"; btnColor: c_green; width: 120; onClicked: if(onAddSelected) onAddSelected() } 
        } 
    } 
}