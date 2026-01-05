import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import "../components"
import ".."

Dialog {
    id: root
    x: (parent.width - width)/2
    y: (parent.height - height)/2
    width: 950
    height: 700
    modal: true
    closePolicy: Popup.NoAutoClose 

    property var jsonData: ({}) 
    property string targetIp: ""
    property bool useAuth: false

    function safeGet(obj, prop, def="-") { return (obj && obj[prop]) ? obj[prop] : def }

    background: Rectangle {
        color: Theme.bg_main
        radius: Theme.radius
        border.color: Theme.border
        border.width: 1
    }

    // --- Modern Header ---
    header: Item {
        width: parent.width; height: 55
        
        Rectangle {
            anchors.fill: parent; color: Theme.bg_panel
            radius: Theme.radius
            Rectangle { anchors.bottom: parent.bottom; width: parent.width; height: 10; color: Theme.bg_panel }
        }

        TabBar {
            id: bar
            width: 350; height: 40; anchors.centerIn: parent
            background: Item{}
            
            Repeater {
                model: ["System Overview", "Printers Management"]
                TabButton {
                    text: modelData
                    width: 175
                    contentItem: Text { 
                        text: parent.text; font.bold: true; 
                        color: parent.checked ? Theme.accent : Theme.text_dim
                        horizontalAlignment: Text.AlignHCenter; verticalAlignment: Text.AlignVCenter 
                    }
                    background: Rectangle {
                        color: parent.checked ? Qt.rgba(Theme.accent.r, Theme.accent.g, Theme.accent.b, 0.15) : "transparent"
                        radius: 8
                    }
                }
            }
        }
        
        TButton {
            text: "✕"; width: 32; height: 32
            anchors.right: parent.right; anchors.verticalCenter: parent.verticalCenter; anchors.rightMargin: 15
            btnColor: Theme.error
            onClicked: root.close()
        }
    }

    StackLayout {
        anchors.fill: parent; anchors.margins: 20
        currentIndex: bar.currentIndex
        
        // ================= TAB 1: SYSTEM INFO =================
        ScrollView {
            contentWidth: parent.width - 20; contentHeight: 650
            clip: true
            
            GridLayout {
                width: parent.width; columns: 3; columnSpacing: 15; rowSpacing: 15
                
                // 1. Computer Identity (Full Width)
                TCard {
                    Layout.columnSpan: 3; Layout.fillWidth: true; Layout.preferredHeight: 100
                    color: Qt.rgba(Theme.bg_panel.r, Theme.bg_panel.g, Theme.bg_panel.b, 0.9)
                    
                    RowLayout {
                        anchors.fill: parent; anchors.margins: 20; spacing: 25
                        
                        // Large Icon
                        Rectangle {
                            width: 60; height: 60; radius: 30
                            color: Qt.rgba(Theme.primary.r, Theme.primary.g, Theme.primary.b, 0.2)
                            Text { text: "🖥️"; font.pixelSize: 32; anchors.centerIn: parent }
                        }
                        
                        ColumnLayout {
                            Layout.fillWidth: true
                            Label { text: (root.jsonData._ComputerName || root.targetIp).toUpperCase(); font.bold: true; font.pixelSize: 22; color: Theme.text_main }
                            Label { text: "IP Address: " + root.targetIp; color: Theme.accent; font.bold: true }
                        }
                        
                        // OS Details
                        ColumnLayout {
                            Layout.alignment: Qt.AlignRight
                            Label { text: safeGet(root.jsonData.OS, "Caption"); font.bold: true; color: Theme.text_main; font.pixelSize: 14 }
                            Label { text: "Version: " + safeGet(root.jsonData.OS, "Version") + " (" + safeGet(root.jsonData.OS, "OSArchitecture") + ")"; color: Theme.text_dim }
                        }
                    }
                }

                // 2. CPU Card
                TCard {
                    Layout.fillWidth: true; Layout.preferredHeight: 140
                    color: Theme.bg_panel
                    ColumnLayout {
                        anchors.fill: parent; anchors.margins: 15
                        RowLayout {
                            Label { text: "PROCESSOR"; color: Theme.accent; font.bold: true; font.pixelSize: 11; Layout.fillWidth: true }
                            Text { text: "🧠"; font.pixelSize: 20 }
                        }
                        Label { text: safeGet(root.jsonData.CPU, "Name"); color: Theme.text_main; font.bold: true; font.pixelSize: 13; wrapMode: Text.Wrap; Layout.fillWidth: true }
                        Item { Layout.fillHeight: true }
                        Label { text: safeGet(root.jsonData.CPU, "NumberOfCores") + " Cores"; color: Theme.text_dim }
                    }
                }

                // 3. RAM Card
                TCard {
                    Layout.fillWidth: true; Layout.preferredHeight: 140
                    color: Theme.bg_panel
                    ColumnLayout {
                        anchors.fill: parent; anchors.margins: 15
                        RowLayout {
                            Label { text: "MEMORY"; color: Theme.warning; font.bold: true; font.pixelSize: 11; Layout.fillWidth: true }
                            Text { text: "💾"; font.pixelSize: 20 }
                        }
                        Label { 
                            text: { var r = safeGet(root.jsonData.RAM, "TotalPhysicalMemory", 0); return (r==0?"-": (Math.round(r/1073741824*100)/100) + " GB") }
                            color: Theme.text_main; font.bold: true; font.pixelSize: 24 
                        }
                        Item { Layout.fillHeight: true }
                        Label { text: safeGet(root.jsonData.RAM, "Manufacturer"); color: Theme.text_dim; elide: Text.ElideRight; Layout.fillWidth: true }
                    }
                }

                // 4. Model/System Info
                TCard {
                    Layout.fillWidth: true; Layout.preferredHeight: 140
                    color: Theme.bg_panel
                    ColumnLayout {
                        anchors.fill: parent; anchors.margins: 15
                        RowLayout {
                            Label { text: "SYSTEM MODEL"; color: Theme.success; font.bold: true; font.pixelSize: 11; Layout.fillWidth: true }
                            Text { text: "⚙️"; font.pixelSize: 20 }
                        }
                        Label { text: safeGet(root.jsonData.RAM, "Model"); color: Theme.text_main; font.bold: true; font.pixelSize: 14; wrapMode: Text.Wrap; Layout.fillWidth: true }
                        Item { Layout.fillHeight: true }
                        Label { text: "Serial: " + safeGet(root.jsonData.OS, "SerialNumber"); color: Theme.text_dim; font.pixelSize: 11 }
                    }
                }

                // 5. Storage (Full Width Bottom)
                TCard {
                    Layout.columnSpan: 3; Layout.fillWidth: true; Layout.fillHeight: true
                    Layout.minimumHeight: 200
                    color: Theme.bg_panel
                    
                    ColumnLayout {
                        anchors.fill: parent; anchors.margins: 20; spacing: 15
                        Label { text: "STORAGE DEVICES"; color: Theme.primary; font.bold: true; font.pixelSize: 12 }
                        
                        ListView {
                            Layout.fillWidth: true; Layout.fillHeight: true
                            clip: true; spacing: 12
                            model: { var d = root.jsonData.Disks; return d ? (Array.isArray(d)?d:[d]) : [] }
                            
                            delegate: Rectangle {
                                width: parent.width; height: 50
                                color: Theme.bg_input; radius: 6
                                
                                property real total: modelData.Size || 1
                                property real free: modelData.FreeSpace || 0
                                property real usedPct: (total - free) / total
                                
                                RowLayout {
                                    anchors.fill: parent; anchors.margins: 10; spacing: 15
                                    
                                    // Disk Icon/Letter
                                    Rectangle {
                                        width: 30; height: 30; radius: 4; color: Theme.bg_panel
                                        Text { text: (modelData.DeviceID || "?")[0]; color: Theme.accent; font.bold: true; anchors.centerIn: parent }
                                    }
                                    
                                    // Progress Bar
                                    ColumnLayout {
                                        Layout.fillWidth: true; spacing: 4
                                        RowLayout {
                                            Label { text: "Local Disk (" + (modelData.DeviceID || "?") + ")"; color: Theme.text_main; font.bold: true; font.pixelSize: 12 }
                                            Item { Layout.fillWidth: true }
                                            Label { 
                                                text: (Math.round(free/1073741824)) + " GB Free of " + (Math.round(total/1073741824)) + " GB"; 
                                                color: Theme.text_dim; font.pixelSize: 11 
                                            }
                                        }
                                        Rectangle {
                                            Layout.fillWidth: true; height: 6; radius: 3; color: Theme.bg_panel
                                            Rectangle {
                                                width: parent.width * usedPct; height: parent.height; radius: 3
                                                color: usedPct > 0.9 ? Theme.error : (usedPct > 0.75 ? Theme.warning : Theme.success)
                                            }
                                        }
                                    }
                                }
                            }
                        }
                    }
                }
            }
        }

        // ================= TAB 2: PRINTERS =================
        Item {
            ListView {
                id: printerList
                anchors.fill: parent; anchors.margins: 5
                clip: true; spacing: 10
                
                model: { var p = root.jsonData.Printers; return p ? (Array.isArray(p)?p:[p]) : [] }
                
                delegate: TCard {
                    width: printerList.width; height: 75
                    color: Theme.bg_panel
                    border.color: modelData.Default ? Theme.success : Theme.border
                    border.width: modelData.Default ? 2 : 1
                    
                    RowLayout {
                        anchors.fill: parent; anchors.margins: 12; spacing: 15
                        
                        // Icon
                        Rectangle {
                            width: 45; height: 45; radius: 10
                            color: Theme.bg_input
                            Text { text: "🖨️"; font.pixelSize: 22; anchors.centerIn: parent }
                        }
                        
                        // Info
                        ColumnLayout {
                            Layout.fillWidth: true 
                            spacing: 2
                            
                            RowLayout {
                                Layout.fillWidth: true
                                Label { 
                                    text: modelData.Name
                                    font.bold: true; color: Theme.text_main; font.pixelSize: 13
                                    Layout.fillWidth: true; elide: Text.ElideRight 
                                }
                                Rectangle {
                                    visible: modelData.Default === true
                                    width: 60; height: 18; radius: 4; color: Theme.success
                                    Text { text: "DEFAULT"; font.bold: true; font.pixelSize: 10; color: "#FFF"; anchors.centerIn: parent }
                                }
                            }
                            Label { 
                                text: (modelData.PortName || "-") + "  •  " + (modelData.PrinterStatus ? "Status: " + modelData.PrinterStatus : "Idle"); 
                                color: Theme.text_dim; font.pixelSize: 11 
                                Layout.fillWidth: true; elide: Text.ElideRight
                            }
                        }
                        
                        // Actions (Buttons Aligned Right)
                        RowLayout {
                            spacing: 8
                            Layout.alignment: Qt.AlignRight 
                            
                            // دکمه Test Page (بازگردانده شد چون در درخواست قبل از حذف بود)
                            TButton { 
                                text: "Test Page"
                                height: 30; width: 90
                                btnColor: Theme.bg_input; textColor: Theme.text_main
                                onClicked: backend.printer_action(root.targetIp, modelData.Name, "test", "", root.useAuth)
                            }
                            
                            // دکمه Rename
                            TButton { 
                                text: "Rename"
                                height: 30; width: 80
                                btnColor: Theme.bg_input; textColor: Theme.text_main
                                onClicked: renamePopup.open()
                                
                                Popup {
                                    id: renamePopup
                                    width: 240; height: 130
                                    modal: true; focus: true
                                    x: -200; y: 10
                                    background: TCard { color: Theme.bg_panel; border.color: Theme.accent }
                                    
                                    ColumnLayout {
                                        anchors.fill: parent; anchors.margins: 10
                                        Label { text: "Rename Printer:"; color: Theme.text_dim; font.pixelSize: 11 }
                                        TInput { id: newName; text: modelData.Name; Layout.fillWidth: true }
                                        
                                        RowLayout {
                                            Layout.fillWidth: true
                                            TButton { text: "Cancel"; Layout.fillWidth: true; btnColor: Theme.error; onClicked: renamePopup.close() }
                                            TButton { 
                                                text: "Save"; Layout.fillWidth: true; btnColor: Theme.success
                                                onClicked: {
                                                    backend.printer_action(root.targetIp, modelData.Name, "rename", newName.text, root.useAuth)
                                                    renamePopup.close()
                                                }
                                            }
                                        }
                                    }
                                }
                            }
                        }
                    }
                }
            }
        }
    }
}