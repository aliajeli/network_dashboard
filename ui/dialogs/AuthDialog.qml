import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import "../components"
import ".."

Dialog {
    id: root
    x: (parent.width - width)/2
    y: (parent.height - height)/2
    width: 350
    height: 320
    modal: true
    closePolicy: Popup.CloseOnEscape

    property string targetIp: ""
    property var onConnect 

    background: Rectangle {
        color: Theme.bg_panel
        radius: Theme.radius
        border.color: Theme.accent
        border.width: 1
    }

    ColumnLayout {
        anchors.fill: parent; anchors.margins: 20; spacing: 15
        
        Label { 
            text: "Connect to System"
            font.bold: true; font.pixelSize: 16; color: Theme.accent
            Layout.alignment: Qt.AlignHCenter
        }
        
        Label { text: "Target IP: " + root.targetIp; color: Theme.text_dim; Layout.alignment: Qt.AlignHCenter }
        
        TCheck { 
            id: chkAnon
            text: "Anonymous (No Auth)"
            checked: false
            onClicked: {
                if(checked) { txtUser.text = ""; txtPass.text = "" }
            }
        }
        
        TInput { 
            id: txtUser; placeholderText: "Username"
            Layout.fillWidth: true; enabled: !chkAnon.checked
        }
        
        TInput { 
            id: txtPass; placeholderText: "Password"
            echoMode: TextInput.Password
            Layout.fillWidth: true; enabled: !chkAnon.checked
        }
        
        Item { Layout.fillHeight: true } 
        
        RowLayout {
            Layout.fillWidth: true
            TButton { 
                text: "Cancel"; btnColor: Theme.error; Layout.fillWidth: true
                onClicked: root.close() 
            }
            TButton { 
                text: "Get Info"; btnColor: Theme.success; Layout.fillWidth: true
                // --- FIX: شرط فعال شدن دکمه ---
                enabled: chkAnon.checked || (txtUser.text.length > 0 && txtPass.text.length > 0)
                opacity: enabled ? 1.0 : 0.5
                // -----------------------------
                onClicked: {
                    if (onConnect) onConnect(root.targetIp, txtUser.text, txtPass.text, !chkAnon.checked)
                    root.close()
                } 
            }
        }
    }
}