import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import "../components"
import ".." // Theme

Dialog { 
    id: root
    x: (parent.width - width)/2; y: (parent.height - height)/2
    width: 900; height: 550
    modal: true; closePolicy: Popup.CloseOnEscape
    
    property bool isEditMode: false
    property int editDistIdx: -1; property int editBranchIdx: -1; property int editSysIdx: -1
    property alias destDistrictText: destInpDist.text; property alias destBranchText: destInpBranch.text; property alias destNameText: destInpName.text; property alias destIpText: destInpIp.text
    property bool selectAllChecked: false

    property var destinationsModel
    property var onSaveDest
    property var onUpdateCount
    property var onOpenEdit
    property var onDeleteDest
    property var onToggleBranch
    property var onToggleAll
    property var onClearSelection

    // پس‌زمینه دیالوگ
    background: Rectangle { 
        color: Theme.bg_panel
        radius: Theme.radius
        border.color: Theme.accent
        border.width: 1 
    }
    Row { 
        anchors.fill: parent; anchors.margins: 20; spacing: 20
        Column { 
            width: 280; spacing: 12
            Label { text: root.isEditMode ? "Edit Destination" : "Manage Destinations"; color: Theme.accent; font.bold: true; font.pixelSize: 16; anchors.horizontalCenter: parent.horizontalCenter } 
            Rectangle { width: parent.width; height: 1; color: Theme.bg_input }
            Label { text: "District Name"; color: Theme.text_dim; font.pixelSize: 12 } TInput { id: destInpDist; width: parent.width; placeholderText: "e.g. Gilan" }
            Label { text: "Branch Name"; color: Theme.text_dim; font.pixelSize: 12 } TInput { id: destInpBranch; width: parent.width; placeholderText: "e.g. Lahijan" }
            Label { text: "System Name"; color: Theme.text_dim; font.pixelSize: 12 } TInput { id: destInpName; width: parent.width; placeholderText: "e.g. Server Backup" }
            Label { text: "IP Address"; color: Theme.text_dim; font.pixelSize: 12 } TInput { id: destInpIp; width: parent.width; placeholderText: "10.0.0.X"; validator: RegularExpressionValidator { regularExpression: /^((25[0-5]|2[0-4][0-9]|[01]?[0-9][0-9]?)\.){0,3}(25[0-5]|2[0-4][0-9]|[01]?[0-9][0-9]?)?$/ } }
            Item { height: 10; width: 1 }
            TButton { 
                text: root.isEditMode ? "Save Changes" : "Add Destination"; width: parent.width; btnColor: Theme.success
                onClicked: { if(destInpDist.text !== "" && destInpBranch.text !== "" && destInpName.text !== "") { if(onSaveDest) onSaveDest(destInpDist.text, destInpBranch.text, destInpName.text, destInpIp.text); if(!root.isEditMode) { destInpName.text = ""; destInpIp.text = "" } } } 
            }
        }
        Rectangle { width: 1; height: parent.height; color: Theme.accent }
        ColumnLayout { 
            width: parent.width - 300 - 20; height: parent.height; spacing: 10
            RowLayout { 
                Layout.fillWidth: true
                TCheck { id: chkSelectAll; text: "Select All"; checked: root.selectAllChecked; onClicked: if(onToggleAll) onToggleAll(checked) } 
                Item { Layout.fillWidth: true } 
                TButton { text: "Clear Selection"; width: 120; btnColor: Theme.warning; onClicked: if(onClearSelection) onClearSelection() } 
                TButton { 
                    text: "Apply"; width: 80; btnColor: Theme.success
                    onClicked: { if(root.isEditMode) { root.isEditMode = false; destInpName.text = ""; destInpIp.text = ""; destInpBranch.text = ""; destInpDist.text = "" } else { root.close() } } 
                }
            }
            ListView {
                Layout.fillWidth: true; Layout.fillHeight: true; clip: true; spacing: 15
                model: root.destinationsModel
                delegate: Column {
                    id: distDelegate
                    width: parent.width - 10; spacing: 0
                    property int dIdx: index
                    property string distName: model.districtName
                    Rectangle {
                        width: parent.width; height: 35; color: Theme.bg_input; radius: 5
                        RowLayout { anchors.fill: parent; anchors.leftMargin: 10; anchors.rightMargin: 10; Label { text: model.districtName; color: Theme.accent; font.bold: true; font.pixelSize: 14; Layout.fillWidth: true } }
                    }
                    Column {
                        width: parent.width; padding: 5; spacing: 8
                        Repeater {
                            model: branches
                            delegate: Rectangle {
                                id: branchCard
                                width: parent.width; height: branchCol.implicitHeight + 20; color: Theme.bg_panel; radius: 6; border.color: Theme.bg_input; border.width: 1
                                property int bIdx: index
                                property string bName: model.branchName
                                Column {
                                    id: branchCol
                                    width: parent.width; anchors.centerIn: parent; spacing: 8
                                    Row {
                                        leftPadding: 10; spacing: 10
                                        TCheck { checked: model.checked; onClicked: { if(onToggleBranch) onToggleBranch(distDelegate.dIdx, bIdx, checked); if(onUpdateCount) onUpdateCount() } }
                                        Label { text: model.branchName; color: Theme.text_main; font.bold: true; font.pixelSize: 13; anchors.verticalCenter: parent.verticalCenter }
                                    }
                                    Flow {
                                        width: parent.width - 20; anchors.horizontalCenter: parent.horizontalCenter; spacing: 8
                                        Repeater {
                                            model: systems
                                            delegate: Rectangle {
                                                height: 26; width: sysLabel.implicitWidth + 30; radius: 13 
                                                color: model.checked ? Theme.primary : Qt.darker(Theme.bg_panel, 1.2); border.color: model.checked ? Theme.accent : Theme.text_dim; border.width: 1
                                                MouseArea {
                                                    anchors.fill: parent; acceptedButtons: Qt.LeftButton | Qt.RightButton
                                                    onClicked: (mouse) => {
                                                        if (mouse.button === Qt.LeftButton) { model.checked = !model.checked; if(onUpdateCount) onUpdateCount() } else { destSysMenu.popup() }
                                                    }
                                                }
                                                Row { anchors.centerIn: parent; spacing: 5; Label { id: sysLabel; text: model.sysName; color: model.checked ? "#ffffff" : Theme.text_main; font.pixelSize: 11; font.bold: model.checked } }
                                                Menu {
                                                    id: destSysMenu
                                                    padding: 5; background: Rectangle { implicitWidth: 120; implicitHeight: 80; color: Theme.bg_panel; border.color: Theme.accent; border.width: 1; radius: 8 }
                                                    delegate: MenuItem { id: dMenuItem; implicitWidth: 110; implicitHeight: 30; contentItem: Text { text: dMenuItem.text; color: dMenuItem.highlighted ? Theme.text_main : Theme.text_main_dim; font.pixelSize: 12; horizontalAlignment: Text.AlignLeft; verticalAlignment: Text.AlignVCenter; leftPadding: 10 } background: Rectangle { color: dMenuItem.highlighted ? Theme.primary : "transparent"; radius: 4 } }
                                                    MenuItem { text: "Edit"; onTriggered: if(onOpenEdit) onOpenEdit(distDelegate.dIdx, branchCard.bIdx, index, distDelegate.distName, branchCard.bName, model.sysName, model.sysIp) }
                                                    MenuItem { text: "Delete"; onTriggered: if(onDeleteDest) onDeleteDest(distDelegate.dIdx, branchCard.bIdx, index) }
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