import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import "../components"
import ".."

Dialog {
    id: root
    x: (parent.width - width)/2
    y: (parent.height - height)/2
    width: 950; height: 680
    modal: true
    closePolicy: Popup.NoAutoClose 

    property var jsonData: ({}) 
    property string targetIp: ""
    property bool useAuth: false

    // تابع کمکی
    function safeGet(obj, prop, def="-") { return (obj && obj[prop]) ? obj[prop] : def }

    background: Rectangle {
        color: Theme.bg_main
        radius: Theme.radius
        border.color: Theme.border
        border.width: 1
    }

    header: Item {
        width: parent.width; height: 60
        Rectangle { color: Theme.bg_panel; anchors.fill: parent; radius: Theme.radius; Rectangle { anchors.bottom: parent.bottom; width: parent.width; height: 10; color: Theme.bg_panel } }

        TabBar {
            id: bar
            width: 400; height: 45; anchors.centerIn: parent
            background: Item{}
            TabButton {
                text: "System Info"; width: 200
                contentItem: Text { text: parent.text; color: parent.checked ? Theme.accent : Theme.text_dim; font.bold: true; horizontalAlignment: Text.AlignHCenter; verticalAlignment: Text.AlignVCenter }
                background: Rectangle { color: parent.checked ? Qt.rgba(Theme.accent.r, Theme.accent.g, Theme.accent.b, 0.1) : "transparent"; radius: 8 }
            }
            TabButton {
                text: "Printers"; width: 200
                contentItem: Text { text: parent.text; color: parent.checked ? Theme.accent : Theme.text_dim; font.bold: true; horizontalAlignment: Text.AlignHCenter; verticalAlignment: Text.AlignVCenter }
                background: Rectangle { color: parent.checked ? Qt.rgba(Theme.accent.r, Theme.accent.g, Theme.accent.b, 0.1) : "transparent"; radius: 8 }
            }
        }
        TButton { text: "✕"; width: 35; height: 35; anchors.right: parent.right; anchors.verticalCenter: parent.verticalCenter; anchors.rightMargin: 20; btnColor: Theme.error; onClicked: root.close() }
    }

    StackLayout {
        anchors.fill: parent; anchors.margins: 25
        currentIndex: bar.currentIndex
        
        // --- TAB 1: System Overview ---
        ScrollView {
            contentWidth: parent.width - 50; contentHeight: 600
            clip: true
            
            GridLayout {
                width: parent.width; columns: 2; columnSpacing: 20; rowSpacing: 20
                
                // OS Card
                TCard {
                    Layout.fillWidth: true; Layout.preferredHeight: 160
                    color: Qt.rgba(Theme.bg_panel.r, Theme.bg_panel.g, Theme.bg_panel.b, 0.8)
                    RowLayout {
                        anchors.fill: parent; anchors.margins: 20; spacing: 20
                        Rectangle { width: 80; height: 80; radius: 40; color: Qt.rgba(Theme.primary.r,Theme.primary.g,Theme.primary.b,0.2)
                            Text { text: "🪟"; font.pixelSize: 40; anchors.centerIn: parent } }
                        ColumnLayout {
                            Layout.fillWidth: true
                            Label { text: "OPERATING SYSTEM"; color: Theme.primary; font.bold: true; font.pixelSize: 11; opacity: 0.8 }
                            Label { text: safeGet(root.jsonData.OS, "Caption"); color: Theme.text_main; font.bold: true; font.pixelSize: 20; Layout.fillWidth: true; wrapMode: Text.Wrap }
                            Label { text: "Build: " + safeGet(root.jsonData.OS, "Version"); color: Theme.text_dim }
                            Label { text: "Computer Name: " + (root.jsonData._ComputerName || root.targetIp); color: Theme.text_dim }
                        }
                    }
                }

                // CPU Card
                TCard {
                    Layout.fillWidth: true; Layout.preferredHeight: 160
                    color: Qt.rgba(Theme.bg_panel.r, Theme.bg_panel.g, Theme.bg_panel.b, 0.8)
                    RowLayout {
                        anchors.fill: parent; anchors.margins: 20; spacing: 20
                        Rectangle { width: 80; height: 80; radius: 40; color: Qt.rgba(Theme.accent.r,Theme.accent.g,Theme.accent.b,0.2)
                            Text { text: "🧠"; font.pixelSize: 40; anchors.centerIn: parent } }
                        ColumnLayout {
                            Layout.fillWidth: true
                            Label { text: "PROCESSOR"; color: Theme.accent; font.bold: true; font.pixelSize: 11; opacity: 0.8 }
                            Label { text: safeGet(root.jsonData.CPU, "Name"); color: Theme.text_main; font.bold: true; font.pixelSize: 14; Layout.fillWidth: true; wrapMode: Text.Wrap }
                            Label { text: "Cores: " + safeGet(root.jsonData.CPU, "NumberOfCores"); color: Theme.text_dim }
                        }
                    }
                }

                // RAM Card
                TCard {
                    Layout.fillWidth: true; Layout.preferredHeight: 160
                    color: Qt.rgba(Theme.bg_panel.r, Theme.bg_panel.g, Theme.bg_panel.b, 0.8)
                    RowLayout {
                        anchors.fill: parent; anchors.margins: 20; spacing: 20
                        Rectangle { width: 80; height: 80; radius: 40; color: Qt.rgba(Theme.warning.r,Theme.warning.g,Theme.warning.b,0.2)
                            Text { text: "💾"; font.pixelSize: 40; anchors.centerIn: parent } }
                        ColumnLayout {
                            Layout.fillWidth: true
                            Label { text: "MEMORY"; color: Theme.warning; font.bold: true; font.pixelSize: 11; opacity: 0.8 }
                            Label { 
                                text: { var r = safeGet(root.jsonData.RAM, "TotalPhysicalMemory", 0); return (r==0?"-": (Math.round(r/1073741824*100)/100) + " GB") }
                                color: Theme.text_main; font.bold: true; font.pixelSize: 22 
                            }
                            Label { text: "System: " + safeGet(root.jsonData.RAM, "Manufacturer"); color: Theme.text_dim; Layout.fillWidth: true; elide: Text.ElideRight }
                        }
                    }
                }

                // Storage List (Full Height)
                TCard {
                    Layout.fillWidth: true; Layout.fillHeight: true
                    color: Qt.rgba(Theme.bg_panel.r, Theme.bg_panel.g, Theme.bg_panel.b, 0.8)
                    ColumnLayout {
                        anchors.fill: parent; anchors.margins: 20; spacing: 15
                        Label { text: "STORAGE DEVICES"; color: Theme.success; font.bold: true; font.pixelSize: 11; opacity: 0.8 }
                        ListView {
                            Layout.fillWidth: true; Layout.fillHeight: true; clip: true; spacing: 15
                            model: { var d = root.jsonData.Disks; return d ? (Array.isArray(d)?d:[d]) : [] }
                            delegate: ColumnLayout {
                                width: parent.width; spacing: 5
                                property real total: modelData.Size || 1; property real free: modelData.FreeSpace || 0; property real pct: (total-free)/total
                                RowLayout {
                                    Label { text: "Drive " + (modelData.DeviceID || "?"); font.bold: true; color: Theme.text_main }
                                    Item { Layout.fillWidth: true }
                                    Label { text: Math.round(free/1073741824) + " GB Free"; color: Theme.text_dim; font.pixelSize: 11 }
                                }
                                Rectangle {
                                    Layout.fillWidth: true; height: 8; radius: 4; color: Theme.bg_input
                                    Rectangle { width: parent.width * pct; height: parent.height; radius: 4; color: pct>0.9 ? Theme.error : Theme.success }
                                }
                            }
                        }
                    }
                }
            }
        }

        // --- TAB 2: Printers ---
        ListView {
            clip: true; spacing: 12
            model: { var p = root.jsonData.Printers; return p ? (Array.isArray(p)?p:[p]) : [] }
            delegate: TCard {
                width: parent.width; height: 90
                color: Theme.bg_panel
                border.color: modelData.Default ? Theme.success : Theme.border
                border.width: modelData.Default ? 2 : 1
                RowLayout {
                    anchors.fill: parent; anchors.margins: 15; spacing: 20
                    Rectangle { width: 50; height: 50; radius: 12; color: Theme.bg_input; Text { text: "🖨️"; font.pixelSize: 24; anchors.centerIn: parent } }
                    ColumnLayout {
                        Layout.fillWidth: true
                        Label { text: modelData.Name; font.bold: true; color: Theme.text_main; font.pixelSize: 14 }
                        Label { text: "Status: " + (modelData.PrinterStatus || "Idle"); color: Theme.text_dim; font.pixelSize: 11 }
                    }
                    TButton { text: "Set Default"; visible: !modelData.Default; btnColor: Theme.primary; onClicked: backend.printer_action(root.targetIp, modelData.Name, "default", "", root.useAuth) }
                    TButton { text: "Print Test"; btnColor: Theme.bg_input; textColor: Theme.text_main; onClicked: backend.printer_action(root.targetIp, modelData.Name, "test", "", root.useAuth) }
                }
            }
        }
    }
}