import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import "../components"
import ".." // Theme

TCard {
    id: operations

    property var filesModel
    
    // Signals
    signal requestOpenFileBrowser(bool isFolder)
    signal requestOpenDestDialog()
    signal requestStartCopy()
    signal requestStartDelete()
    signal requestStartReplace()
    signal requestStartRename()
    signal requestStartSingleRename()
    signal requestStartServiceStop()
    signal requestStartServiceStart()
    signal requestStartSendMessage()

    // Aliases
    property alias destPathText: txtDestPath.text
    property alias userText: txtUser.text
    property alias passText: txtPass.text
    property alias authChecked: chkAuth.checked
    property alias svcListText: txtSvcList.text
    property alias stopBeforeChecked: chkStopBefore.checked
    property alias startAfterChecked: chkStartAfter.checked
    property alias msgAfterChecked: chkSendMsgAfter.checked
    property alias msgBodyText: txtMessageBody.text
    property alias replacePrefixText: txtReplacePrefix.text
    property alias renTagText: txtRenTag.text
    property alias renPrefixChecked: chkRenPrefix.checked
    property alias renOldText: txtRenOld.text
    property alias renNewText: txtRenNew.text
    property alias svcActionText: txtSvcAction.text

    Label { text: "Operations"; x: 15; y: 10; font.bold: true; font.pixelSize: 14; color: Theme.accent }
    
    Row { x: 15; y: 40; spacing: 10; 
        TButton { width: 90; text: qsTr("Add File"); onClicked: operations.requestOpenFileBrowser(false) } 
        TButton { width: 90; text: qsTr("Add Folder"); onClicked: operations.requestOpenFileBrowser(true) } 
        TButton { width: 90; text: qsTr("Clear All"); btnColor: Theme.warning; onClicked: backend.clear_files() } 
        TButton { width: 90; text: qsTr("Destinations"); btnColor: Theme.primary; onClicked: operations.requestOpenDestDialog() } 
    }
    
    Rectangle { x: 15; y: 80; width: 390; height: 85; color: Theme.bg_input; radius: 5; border.color: Theme.border; 
        clip: true
        GridView { id: fileGrid; anchors.fill: parent; anchors.margins: 5; model: filesModel; cellWidth: width / 2; cellHeight: 40
            delegate: Item { width: fileGrid.cellWidth; height: fileGrid.cellHeight
                Rectangle { width: parent.width - 5; height: 35; anchors.horizontalCenter: parent.horizontalCenter; color: Theme.bg_panel; radius: 4
                    RowLayout { anchors.fill: parent; anchors.leftMargin: 8; anchors.rightMargin: 8; spacing: 8
                        TIcon { iconType: model.fileType; iconColor: model.fileType === "Folder" ? Theme.warning : Theme.accent; panelColor: Theme.bg_panel }
                        Label { text: model.fileName; color: Theme.text_main; font.pixelSize: 11; elide: Text.ElideRight; Layout.fillWidth: true; verticalAlignment: Text.AlignVCenter }
                        TIcon { iconType: "Close"; iconColor: Theme.error; MouseArea { anchors.fill: parent; onClicked: filesModel.remove(index) } }
                    }
                }
            }
        }
    }
    
    Column { x: 15; y: 180; spacing: 6; 
        TInput { id: txtDestPath; width: 390; placeholderText: qsTr("Path : C:\\Destination Path") } 
        TCheck { id: chkAuth; text: qsTr("Use Authentication"); width: 167; palette.windowText: Theme.text_main } 
        Row { spacing: 10; 
            TInput { id: txtUser; width: 190; placeholderText: qsTr("Username"); enabled: chkAuth.checked } 
            TInput { id: txtPass; width: 190; placeholderText: qsTr("Password"); echoMode: TextInput.Password; enabled: chkAuth.checked } 
        } 
        TInput { width: 390; placeholderText: qsTr("Service 1, Service 2, ..."); id: txtSvcList } 
        Row { spacing: 20; 
            TCheck { text: qsTr("Stop Before"); id: chkStopBefore; palette.windowText: Theme.text_main } 
            TCheck { text: qsTr("Start After"); id: chkStartAfter; palette.windowText: Theme.text_main } 
            
        } 
    }

    Row { x: 15; y: 360; spacing: 10; 
        TButton { width: 80; text: qsTr("Copy"); onClicked: operations.requestStartCopy() } 
        TButton { width: 80; text: qsTr("Delete"); btnColor: Theme.error; onClicked: operations.requestStartDelete() } 
        TInput { id: txtReplacePrefix; width: 110; placeholderText: qsTr("Prefix") } 
        TButton { width: 90; text: qsTr("Replace"); btnColor: Theme.primary; onClicked: operations.requestStartReplace() } 
    }
    
    Row { x: 15; y: 398; spacing: 10; 
        TCheck { id: chkRenPrefix; width: 80; text: qsTr("Prefix"); checked: true; onClicked: chkRenSuffix.checked = false; palette.windowText: Theme.text_main } 
        TCheck { id: chkRenSuffix; width: 80; text: qsTr("Suffix"); onClicked: chkRenPrefix.checked = false; palette.windowText: Theme.text_main } 
        TInput { width: 110; placeholderText: qsTr("String"); id: txtRenTag } 
        TButton { width: 90; text: qsTr("Rename"); onClicked: operations.requestStartRename() } 
    }
    
    Row { x: 15; y: 436; spacing: 10; 
        TInput { width: 130; placeholderText: qsTr("Old Name"); id: txtRenOld } 
        TInput { width: 130; placeholderText: qsTr("New Name"); id: txtRenNew } 
        TButton { width: 110; text: qsTr("Single Rename"); onClicked: operations.requestStartSingleRename() } 
    }
    
    Row { x: 15; y: 474; spacing: 10; 
        TInput { id: txtSvcAction; width: 190; placeholderText: qsTr("Service Name") } 
        TButton { width: 90; text: qsTr("Stop Svc"); btnColor: Theme.warning; onClicked: operations.requestStartServiceStop() } 
        TButton { width: 90; text: qsTr("Start Svc"); btnColor: Theme.success; onClicked: operations.requestStartServiceStart() } 
    }
    
    TextArea { id: txtMessageBody; x: 15; y: 512; width: 390; height: 70; hoverEnabled: false; 
        palette.text: Theme.text_main; palette.base: Theme.bg_input; color: Theme.text_main; font.pixelSize: 12; 
        placeholderText: qsTr("Write your Message ..."); wrapMode: Text.Wrap; 
        background: Rectangle { color: Theme.bg_input; radius: 5; border.color: parent.activeFocus ? Theme.accent : "transparent"; border.width: 1 } 
    }
    
    Row { x: 15; y: 592; spacing: 10; 
        TCheck { id: chkSendMsgAfter; width: 240; text: qsTr("Send Message after Operation"); palette.windowText: Theme.text_main } 
        TButton { width: 140; text: qsTr("Send Message"); onClicked: operations.requestStartSendMessage() } 
    }
}