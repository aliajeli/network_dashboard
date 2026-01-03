import QtQuick
import QtQuick.Controls
import "../components"
import ".." // Theme

Dialog { 
    id: root
    x: (parent.width - width)/2; y: (parent.height - height)/2
    width: 340; height: 420
    modal: true; closePolicy: Popup.CloseOnEscape
    
    property bool isEditMode: false
    property int editBranchIndex: -1
    property int editSysIndex: -1
    
    // Alias ها
    property alias branchText: inpBranch.text
    property alias nameText: inpName.text
    property alias ipText: inpIp.text
    
    // --- FIX: این خط باعث خطا می‌شد اگر cmbType درست تعریف نشده بود ---
    property alias typeIndex: cmbType.currentIndex
    // -------------------------------------------------------------
    
    property var typeModel
    property var onSave

    // پس‌زمینه دیالوگ
    background: Rectangle { 
        color: Theme.bg_panel
        radius: Theme.radius
        border.color: Theme.accent
        border.width: 1 
    }
    
    Column { 
        anchors.centerIn: parent; spacing: 15; width: 300
        
        Label { 
            text: root.isEditMode ? "Edit System" : "Add New System"
            color: Theme.accent; font.bold: true; font.pixelSize: 14
            anchors.horizontalCenter: parent.horizontalCenter 
        } 
        
        Rectangle { width: parent.width; height: 1; color: Theme.bg_input } 
        
        Label { text: "Branch Name"; color: Theme.text_dim; font.pixelSize: 12 } 
        TInput { id: inpBranch; width: parent.width; placeholderText: "e.g. Lahijan" } 
        
        Label { text: "System Type"; color: Theme.text_dim; font.pixelSize: 12 } 
        // --- استفاده از TComboBox ---
        TComboBox { id: cmbType; width: parent.width; model: root.typeModel } 
        
        Label { text: "System Name"; color: Theme.text_dim; font.pixelSize: 12 } 
        TInput { id: inpName; width: parent.width; placeholderText: "e.g. Client 1" } 
        
        Label { text: "IP Address"; color: Theme.text_dim; font.pixelSize: 12 } 
        TInput { 
            id: inpIp; width: parent.width; placeholderText: "192.168.1.X"
            validator: RegularExpressionValidator { regularExpression: /^((25[0-5]|2[0-4][0-9]|[01]?[0-9][0-9]?)\.){0,3}(25[0-5]|2[0-4][0-9]|[01]?[0-9][0-9]?)?$/ } 
        }
        
        Row { 
            width: parent.width; spacing: 10
            property int visibleCount: root.isEditMode ? 2 : 3
            property int buttonWidth: (width - (spacing * (visibleCount - 1))) / visibleCount
            
            TButton { text: "Cancel"; width: parent.buttonWidth; btnColor: Theme.error; onClicked: root.close() } 
            
            TButton { 
                text: "Add & Cont."; width: parent.buttonWidth; btnColor: Theme.primary; visible: !root.isEditMode
                onClicked: { if(inpBranch.text !== "" && inpName.text !== "") { if(onSave) onSave(inpBranch.text, cmbType.currentText, inpName.text, inpIp.text); inpName.text = ""; inpIp.text = "" } } 
            } 
            
            TButton { 
                text: root.isEditMode ? "Save" : "Add"; width: parent.buttonWidth; btnColor: Theme.success
                onClicked: { if(inpBranch.text !== "" && inpName.text !== "") { if(onSave) onSave(inpBranch.text, cmbType.currentText, inpName.text, inpIp.text); root.close() } } 
            } 
        } 
    } 
}