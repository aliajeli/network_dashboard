import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import "../components"
import ".." // دسترسی به Theme

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

    // پس‌زمینه دیالوگ با تم جدید
    background: Rectangle { 
        color: Theme.bg_panel
        radius: Theme.radius
        border.color: Theme.accent
        border.width: 1 
    }
    
    ColumnLayout { 
        anchors.fill: parent; anchors.margins: 10; spacing: 10
        
        Label { 
            text: root.browseFolderMode ? "Select Folder(s)" : "Select File(s)"
            color: Theme.accent
            font.bold: true; font.pixelSize: 14
            Layout.alignment: Qt.AlignHCenter 
        } 
        
        TInput { 
            text: root.currentBrowsePath
            Layout.fillWidth: true
            readOnly: true 
        }
        
        RowLayout { 
            Layout.fillWidth: true; Layout.fillHeight: true; spacing: 10
            
            // --- Quick Access List ---
            Rectangle { 
                Layout.fillHeight: true; Layout.preferredWidth: 150
                color: Theme.bg_input
                radius: 4; clip: true
                
                ListView { 
                    id: quickList
                    anchors.fill: parent; anchors.margins: 2
                    model: root.quickAccessModel; spacing: 2
                    
                    delegate: Rectangle { 
                        width: ListView.view.width 
                        height: 26; color: "transparent"
                        
                        RowLayout { 
                            anchors.fill: parent; anchors.leftMargin: 5
                            
                            TIcon { 
                                iconType: model.iconType
                                iconColor: Theme.accent
                                panelColor: Theme.bg_panel 
                            } 
                            
                            Label { 
                                text: model.name
                                color: Theme.text_main
                                font.pixelSize: 11
                                elide: Text.ElideRight
                                Layout.fillWidth: true 
                            } 
                        } 
                        
                        MouseArea { 
                            anchors.fill: parent
                            cursorShape: Qt.PointingHandCursor
                            onClicked: if(onRefreshDir) onRefreshDir(model.path) 
                        } 
                    } 
                } 
            }

            // --- Directory List ---
            Rectangle { 
                Layout.fillWidth: true; Layout.fillHeight: true
                color: Theme.bg_input
                radius: 4
                
                ListView { 
                    id: fileList
                    anchors.fill: parent; anchors.margins: 5
                    clip: true; model: root.dirModel
                    
                    delegate: Rectangle { 
                        width: ListView.view.width 
                        height: 30; color: "transparent"
                        
                        RowLayout { 
                            anchors.fill: parent; spacing: 5
                            
                            // چک باکس
                            TCheck { 
                                visible: model.type !== "Parent" && (root.browseFolderMode ? model.type === "Folder" : model.type === "File")
                                checked: model.checked
                                onClicked: model.checked = checked
                                // اینجا قبلاً خطایی بود که برطرف شد
                            }
                            
                            // آیتم فایل/فولدر
                            Item { 
                                Layout.fillWidth: true; Layout.fillHeight: true
                                
                                RowLayout { 
                                    anchors.fill: parent
                                    
                                    TIcon { 
                                        iconType: model.type === "Parent" ? "Up" : model.type
                                        // استفاده از رنگ‌های تم
                                        iconColor: model.type === "Folder" ? Theme.warning : (model.type === "Parent" ? Theme.accent : Theme.text_main)
                                        panelColor: Theme.bg_input
                                    } 
                                    
                                    Label { 
                                        text: model.name
                                        color: Theme.text_main
                                        font.pixelSize: 12
                                        Layout.fillWidth: true; elide: Text.ElideRight 
                                    } 
                                } 
                                
                                MouseArea { 
                                    anchors.fill: parent
                                    cursorShape: Qt.PointingHandCursor
                                    onClicked: { 
                                        if (model.type === "Folder" || model.type === "Parent") { 
                                            if(onRefreshDir) onRefreshDir(model.path) 
                                        } else if (model.type === "File" && !root.browseFolderMode) {
                                            model.checked = !model.checked 
                                        } 
                                    } 
                                } 
                            } 
                        } 
                    } 
                } 
            } 
        }
        
        Row { 
            Layout.alignment: Qt.AlignRight; spacing: 10
            
            TButton { 
                text: "Cancel"
                btnColor: Theme.error
                onClicked: root.close() 
            } 
            
            TButton { 
                text: "Add Selected"
                btnColor: Theme.success
                width: 120
                onClicked: if(onAddSelected) onAddSelected() 
            } 
        } 
    } 
}