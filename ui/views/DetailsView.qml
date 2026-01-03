import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import "../components"
import ".." // Theme

TCard {
    id: details

    property var logModel
    property real opProgressValue: 0.0
    property string opTotal: "0"
    property string opSuccess: "0"
    property string opWarning: "0"
    property string opError: "0"
    
    signal requestOpenAboutDialog()

    Label { 
        id: lblHeader
        text: qsTr("Event Log")
        x: 15; y: 10
        font.bold: true; font.pixelSize: 14; color: Theme.accent 
    }
    
    Column {
        id: bottomSection
        anchors.bottom: parent.bottom
        anchors.left: parent.left
        anchors.right: parent.right
        anchors.margins: 15
        anchors.bottomMargin: 15
        spacing: 12

        // Progress Bar
        Rectangle { 
            width: parent.width; height: 6; color: Theme.bg_main; radius: 3; 
            Rectangle { 
                height: parent.height; radius: 3; color: Theme.accent; width: parent.width * opProgressValue; 
                Behavior on width { NumberAnimation { duration: 300; easing.type: Easing.InOutQuad } } 
            } 
        }

        // Buttons
        RowLayout { 
            width: parent.width; spacing: 10
            TButton { Layout.preferredWidth: 90; text: qsTr("Clear Log"); btnColor: Theme.bg_input; onClicked: logModel.clear() } 
            TButton { Layout.preferredWidth: 90; text: qsTr("Export Log"); btnColor: Theme.bg_input; onClicked: { var content = ""; for(var i = 0; i < logModel.count; i++) content += logModel.get(i).messageText + "\n"; backend.export_log_to_file(content) } } 
            Item { Layout.fillWidth: true } 
            TButton { Layout.preferredWidth: 80; text: qsTr("About"); btnColor: Theme.bg_input; onClicked: details.requestOpenAboutDialog() }
        }

        Item { width: 1; height: 5 } 
        Label { text: qsTr("Network Summary"); font.pointSize: 11; font.bold: true; color: Theme.accent }

        GridLayout {
            width: parent.width; columns: 4; columnSpacing: 10
            
            component StatCard: Rectangle {
                Layout.fillWidth: true; Layout.preferredHeight: 70
                color: Theme.bg_input; radius: Theme.radius
                property color accentColor
                property string value
                property string title
                
                border.color: Theme.border
                border.width: Theme.border === "transparent" ? 0 : 1

                Rectangle { width: 4; height: parent.height; anchors.left: parent.left; color: accentColor; radius: 2 }
                
                Column { anchors.centerIn: parent; spacing: 2
                    Label { text: value; font.bold: true; font.pixelSize: 22; color: Theme.text_main; anchors.horizontalCenter: parent.horizontalCenter }
                    Label { text: title; font.pixelSize: 10; font.bold: true; color: accentColor; anchors.horizontalCenter: parent.horizontalCenter; opacity: 0.8 }
                }
            }

            StatCard { accentColor: Theme.primary;   value: opTotal;   title: "TOTAL" }
            StatCard { accentColor: Theme.success;  value: opSuccess; title: "DONE" }
            StatCard { accentColor: Theme.warning; value: opWarning; title: "PARTIAL" }
            StatCard { accentColor: Theme.error;    value: opError;   title: "FAILED" }
        }
    }

    // Log Area
    Rectangle { 
        id: logOutputBg
        anchors.top: lblHeader.bottom; anchors.topMargin: 10
        anchors.left: parent.left; anchors.leftMargin: 15
        anchors.right: parent.right; anchors.rightMargin: 15
        anchors.bottom: bottomSection.top; anchors.bottomMargin: 15
        color: Theme.bg_main; radius: 5; border.color: Theme.border; border.width: 1; clip: true; 
        
        ListView { 
            id: logListView
            anchors.fill: parent; anchors.margins: 10; model: logModel; spacing: 5; 
            delegate: Text { 
                text: model.messageText; color: Theme.text_main // Using Theme color instead of log color for consistency, or keep model.messageColor if needed
                font.family: "Consolas"; font.pixelSize: 12
                wrapMode: Text.Wrap; width: logListView.width - 20 
            } 
            onCountChanged: positionViewAtEnd()
        } 
    }
}