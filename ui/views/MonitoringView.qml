import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import "../components"
import ".." // Theme

TCard {
    id: monitoring

    property var branchesModel
    property bool isMonitoringActive
    property string totalCount: "-"
    property string onlineCount: "-"
    property string offlineCount: "-"
    
    property alias pingStatusText: lblPingStatus.text
    property alias pingStatusColor: lblPingStatus.color

    signal requestAddSystem()
    signal requestEditSystem(int bIdx, int sIdx, string branch, string name, string ip, string type)
    signal requestDeleteSystem(int bIdx, int sIdx)

    // --- Top Section ---
    Item {
        id: topSection
        width: parent.width
        height: 160 
        
        Label { text: "Monitoring"; x: 15; y: 10; font.bold: true; font.pixelSize: 14; color: Theme.accent }

        TInput {
            id: txtIpAddress
            x: 15; y: 40; width: 160
            placeholderText: qsTr("IP Address")
            validator: RegularExpressionValidator { regularExpression: /^((25[0-5]|2[0-4][0-9]|[01]?[0-9][0-9]?)\.){0,3}(25[0-5]|2[0-4][0-9]|[01]?[0-9][0-9]?)?$/ }
        }

        TButton {
            id: btnPing
            x: 185; y: 40; width: 110
            text: qsTr("Ping Test")
            onClicked: backend.run_ping(txtIpAddress.text)
        }

        Label {
            id: lblPingStatus
            x: 305; y: 44; width: 100
            text: qsTr("Idle")
            font.pixelSize: 12; color: Theme.text_dim; horizontalAlignment: Text.AlignHCenter
        }

        TButton {
            id: btnAddSys
            x: 15; y: 80; width: 390
            text: qsTr("Add Systems")
            onClicked: monitoring.requestAddSystem()
        }

        TButton {
            id: btnStartMon
            x: 15; y: 118; width: 190
            text: qsTr("Start Monitoring")
            btnColor: Theme.success
            onClicked: backend.start_monitoring()
        }

        TButton {
            id: btnStopMon
            x: 215; y: 118; width: 190
            text: qsTr("Stop Monitoring")
            btnColor: Theme.error
            onClicked: backend.stop_monitoring()
        }
    }

    // --- Bottom Summary ---
    Column {
        id: summarySection
        anchors.bottom: parent.bottom
        anchors.left: parent.left
        anchors.right: parent.right
        anchors.margins: 15
        anchors.bottomMargin: 15
        spacing: 10

        Label { text: qsTr("Monitoring Summary"); font.pointSize: 11; font.bold: true; color: Theme.accent }

        GridLayout {
            width: parent.width
            height: 70
            columns: 3
            columnSpacing: 10

            component MonStatCard: Rectangle {
                Layout.fillWidth: true; Layout.fillHeight: true
                color: Theme.bg_input; radius: Theme.radius
                property color accentColor
                property string value
                property string title
                
                border.color: Theme.border
                border.width: Theme.border === "transparent" ? 0 : 1

                Rectangle { width: 4; height: parent.height; anchors.left: parent.left; color: accentColor; radius: 2 }
                
                Column {
                    anchors.centerIn: parent
                    Label { text: value; font.bold: true; font.pixelSize: 22; color: Theme.text_main; anchors.horizontalCenter: parent.horizontalCenter }
                    Label { text: title; font.pixelSize: 10; font.bold: true; color: accentColor; anchors.horizontalCenter: parent.horizontalCenter; opacity: 0.8 }
                }
            }

            MonStatCard { accentColor: Theme.primary; value: monitoring.totalCount;  title: "TOTAL" }
            MonStatCard { accentColor: Theme.success; value: monitoring.onlineCount; title: "ONLINE" }
            MonStatCard { accentColor: Theme.error;   value: monitoring.offlineCount; title: "OFFLINE" }
        }
    }

    // --- System List ---
    ListView {
        id: branchListView
        anchors.top: topSection.bottom; anchors.topMargin: 10
        anchors.left: parent.left; anchors.leftMargin: 8
        anchors.right: parent.right; anchors.rightMargin: 8
        anchors.bottom: summarySection.top; anchors.bottomMargin: 15
        clip: true; spacing: 8
        model: branchesModel

        delegate: Rectangle {
            id: branchDelegate
            width: branchListView.width 
            height: sysFlow.implicitHeight + 20
            color: Theme.bg_input
            radius: Theme.radius
            border.color: Theme.border
            border.width: Theme.border === "transparent" ? 0 : 1

            property string currentBranchName: model.branchName
            property int currentBranchIndex: index

            Rectangle {
                id: branchNameStrip
                width: 30; anchors.left: parent.left; anchors.top: parent.top; anchors.bottom: parent.bottom
                color: Theme.bg_panel; radius: Theme.radius
                Label {
                    anchors.centerIn: parent; text: model.branchName; rotation: -90
                    color: Theme.accent; font.bold: true; font.pixelSize: 11; font.capitalization: Font.AllUppercase
                }
            }

            Grid {
                id: sysFlow
                x: 35; y: 10
                width: parent.width - 45 
                columns: 5; spacing: 3

                Repeater {
                    model: systems
                    delegate: Rectangle {
                        id: sysItem
                        width: (sysFlow.width - (4 * sysFlow.spacing)) / 5 
                        height: 24
                        
                        color: {
                            if (model.statusColor === "default" || model.statusColor === undefined || model.statusColor === "#3b4252") {
                                return Theme.bg_panel 
                            } else {
                                return model.statusColor 
                            }
                        }
                        
                        radius: 4
                        border.color: Theme.border
                        border.width: 1

                        Label {
                            anchors.centerIn: parent
                            text: model.sysName; font.pixelSize: 9
                            color: isMonitoringActive ? Theme.bg_main : Theme.text_main
                            elide: Text.ElideRight; width: parent.width - 4; horizontalAlignment: Text.AlignHCenter
                        }

                        MouseArea {
                            anchors.fill: parent
                            acceptedButtons: Qt.RightButton
                            onClicked: ctxPopup.open()
                        }

                        // --- FIX: جایگزینی Menu با Custom Popup ---
                        Popup {
                            id: ctxPopup
                            // باز شدن در مرکز آیتم
                            x: (parent.width - width) / 2
                            y: (parent.height - height) / 2
                            width: 120
                            height: 70
                            modal: true
                            focus: true
                            closePolicy: Popup.CloseOnEscape | Popup.CloseOnPressOutside

                            background: Rectangle {
                                color: Theme.bg_panel
                                border.color: Theme.accent
                                border.width: 1
                                radius: 6
                            }

                            ColumnLayout {
                                anchors.fill: parent
                                anchors.margins: 4
                                spacing: 2

                                // دکمه Edit
                                Rectangle {
                                    Layout.fillWidth: true; Layout.fillHeight: true
                                    color: maEdit.containsMouse ? Qt.rgba(Theme.primary.r, Theme.primary.g, Theme.primary.b, 0.3) : "transparent"
                                    radius: 4
                                    Text {
                                        text: "Edit"
                                        color: Theme.text_main
                                        font.pixelSize: 12
                                        anchors.centerIn: parent
                                    }
                                    MouseArea {
                                        id: maEdit; anchors.fill: parent; hoverEnabled: true
                                        onClicked: {
                                            monitoring.requestEditSystem(branchDelegate.currentBranchIndex, index, branchDelegate.currentBranchName, model.sysName, model.sysIp, model.sysType)
                                            ctxPopup.close()
                                        }
                                    }
                                }

                                // دکمه Delete
                                Rectangle {
                                    Layout.fillWidth: true; Layout.fillHeight: true
                                    color: maDel.containsMouse ? Qt.rgba(Theme.error.r, Theme.error.g, Theme.error.b, 0.3) : "transparent"
                                    radius: 4
                                    Text {
                                        text: "Delete"
                                        color: Theme.error // رنگ قرمز برای خطر
                                        font.pixelSize: 12
                                        anchors.centerIn: parent
                                    }
                                    MouseArea {
                                        id: maDel; anchors.fill: parent; hoverEnabled: true
                                        onClicked: {
                                            monitoring.requestDeleteSystem(branchDelegate.currentBranchIndex, index)
                                            ctxPopup.close()
                                        }
                                    }
                                }
                            }
                        }
                        // ---------------------------------------------
                    }
                }
            }
        }
    }
}