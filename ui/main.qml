import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import "components"
import "views"
import "dialogs"
import "." // برای شناختن Theme.qml

ApplicationWindow {
    id: window
    visible: true
    width: 1300
    height: 700 
    x: (Screen.width - width) / 2
    y: ((Screen.height - height) / 2) - 20
    title: qsTr("Network Dashboard")
    flags: Qt.FramelessWindowHint | Qt.Window
    color: "transparent" // پنجره اصلی شفاف است



    property real currentProgress: 0.0

    // // --- Nord Colors ---
    // property color c_bg_dark: "#2e3440"
    // property color c_bg_panel: "#3b4252"
    // property color c_bg_input: "#434c5e"
    // property color c_comment: "#4c566a"
    // property color c_text_main: "#eceff4"
    // property color c_text_dim: "#d8dee9"
    // property color c_accent: "#88c0d0"
    // property color c_primary: "#5e81ac"
    // property color c_green: "#a3be8c"
    // property color c_red: "#bf616a"
    // property color c_orange: "#d08770"
    // property color c_yellow: "#ebcb8b" // اضافه شده برای Warning

    // State Variables
    property string totalCount: "-"
    property string onlineCount: "-"
    property string offlineCount: "-"
    
    // --- Stats Variables ---
    property string opTotal: "0"
    property string opSuccess: "0"
    property string opWarning: "0" // اضافه شده
    property string opError: "0"
    
    property bool isMonitoringActive: false
    property bool isOperationRunning: false 

    // ... (بقیه کدها تا بخش Functions بدون تغییر) ...
    // ... (File Browser Logic & Models بدون تغییر) ...
    
    // File Browser Logic
    property string currentBrowsePath: ""
    property bool browseFolderMode: false

    // Shared Models
    ListModel { id: branchesModel }
    ListModel { id: destinationsModel }
    ListModel { id: filesModel }
    ListModel { id: dirModel } 
    ListModel { id: quickAccessModel }
    ListModel { id: errorReportModel }
    ListModel { id: typeModel; ListElement { text: "Router" } ListElement { text: "Server" } ListElement { text: "NVR" } ListElement { text: "Checkout" } ListElement { text: "Client" } }
    ListModel { id: logModel }

    Component.onCompleted: {
        Theme.setTheme("Nordic") // تم پیش‌فرض
        
        var monData = JSON.parse(backend.load_monitoring())
        branchesModel.clear()
        for(var i=0; i<monData.length; i++) branchesModel.append(monData[i])
        var destData = JSON.parse(backend.load_destinations())
        destinationsModel.clear()
        for(var j=0; j<destData.length; j++) destinationsModel.append(destData[j])
        updateSelectionCount()
    }

    // --- Functions ---
    function updateSelectionCount() {
        var count = 0
        for(var i=0; i < destinationsModel.count; i++) {
            var dist = destinationsModel.get(i)
            for(var j=0; j < dist.branches.count; j++) {
                var branch = dist.branches.get(j)
                for(var k=0; k < branch.systems.count; k++) {
                    if(branch.systems.get(k).checked) count++
                }
            }
        }
        // اگر عملیات در حال اجرا نیست، تعداد کل را از روی انتخاب‌ها آپدیت کن (Live Update)
        if (!isOperationRunning) {
            opTotal = count.toString()
            opSuccess = "0"
            opWarning = "0"
            opError = "0"
        }
    }

    function resetOperationStats() {
        isOperationRunning = true;
        window.currentProgress = 0.0;
        opSuccess = "0";
        opWarning = "0"; // ریست Warning
        opError = "0";
    }

    // --- CONNECTIONS ---
    Connections {
        target: backend
        function onLogSignal(msg, colorCode) { logModel.append({"messageText": msg, "messageColor": colorCode}) }
        function onPingResultSignal(status) { monitoringView.pingStatusText = status; monitoringView.pingStatusColor = (status === "Online") ? c_green : c_red }
        function onUpdateMonitorSignal(branch, name, color) { updateSystemStatus(branch, name, color) }
        
function onUpdateStatsSignal(total, val1, val2) { 
            // اگر عملیات در حال اجراست
            if (isOperationRunning) {
                window.opTotal = total.toString(); 
                window.opSuccess = val1.toString(); 
                window.opError = val2.toString(); 
                
                if (total > 0) {
                    window.currentProgress = (val1 + val2) / total;
                } else {
                    window.currentProgress = 0.0;
                }
            } 
            // اگر عملیات نیست (حالت مانیتورینگ)
            else {
                // --- FIX: استفاده از window. برای آپدیت تضمینی ---
                window.totalCount = total.toString(); 
                window.onlineCount = (val1 === -1) ? "-" : val1.toString(); 
                window.offlineCount = (val2 === -1) ? "-" : val2.toString();
                // ----------------------------------------------
            }
        }
        
        function onOpProgressSignal(total, success, error) {
            if (isOperationRunning) {
                // نکته: چون پایتون فعلا فقط 3 مقدار میفرستد، ما فعلا Warning را 0 در نظر میگیریم
                // یا میتوانید منطق پایتون را تغییر دهید تا 4 مقدار بفرستد.
                // فعلا: Total از پایتون می آید، Success موفق ها، Error ناموفق ها.
                
                opTotal = total.toString(); 
                opSuccess = success.toString(); 
                opError = error.toString(); 
                // opWarning = ... (نیاز به تغییر در پایتون دارد، فعلا 0)
                
                if (total > 0) {
                    window.currentProgress = (success + error) / total;
                } else {
                    window.currentProgress = 0.0;
                }
            }
        }
        
        function onOpFinishedSignal(errorsJson) { 
            window.currentProgress = 1.0; 
            isOperationRunning = false; 
            
            var errors = JSON.parse(errorsJson); 
            
            // --- FIX: شمارش سیستم‌های یونیک ---
            var systemStatusMap = {}; // کلید: IP، مقدار: نوع خطا

            for(var i=0; i < errors.length; i++) {
                var ip = errors[i].ip;
                var reason = errors[i].reason.toLowerCase();
                
                // اگر این سیستم قبلاً ثبت نشده، فرض می‌کنیم خطای معمولی (Warning) است
                if (!systemStatusMap[ip]) {
                    systemStatusMap[ip] = "Warning";
                }
                
                // اگر خطا حیاتی است (آفلاین یا مشکل لاگین)، وضعیت را به Error ارتقا می‌دهیم
                if (reason.includes("offline") || reason.includes("auth failed")) {
                    systemStatusMap[ip] = "Error";
                }
            }

            // حالا تعداد یونیک‌ها را می‌شماریم
            var uniqueWarnCount = 0;
            var uniqueErrCount = 0;
            
            for (var key in systemStatusMap) {
                if (systemStatusMap[key] === "Error") {
                    uniqueErrCount++;
                } else {
                    uniqueWarnCount++;
                }
            }
            
            // آپدیت UI اگر خطایی وجود داشت
            if (errors.length > 0) {
                 window.opWarning = uniqueWarnCount.toString(); 
                 window.opError = uniqueErrCount.toString();    
            }
            // ------------------------------------

            if (errors.length === 0) { 
                messageDialog.msg = "Operation completed successfully on all targets."; 
                messageDialog.isError = false; 
                messageDialog.open() 
            } else { 
                errorReportModel.clear(); 
                for(var k=0; k<errors.length; k++) errorReportModel.append(errors[k]); 
                errorReportDialog.open() 
            } 
        }
        
        function onResetMonitoringSignal() { resetSystemStatus() }
        function onFileAddedSignal(name, path, type) { checkAndAddFile(name, path, type) }
        function onFilesClearedSignal() { filesModel.clear() }
    }

    // ... (بقیه توابع startCopyOperation و غیره بدون تغییر) ...
    // فقط دقت کنید که تابع updateSelectionCount در بالا تغییر کرده است.
    
    // --- OPERATION FUNCTIONS (بدون تغییر) ---
    function startCopyOperation() { 
        resetOperationStats();
        var filesArr = getFilesArray(); var destArr = getDestArray();
        if (filesArr.length === 0) { isOperationRunning=false; messageDialog.msg = "Please select at least one file/folder."; messageDialog.isError = true; messageDialog.open(); return } 
        if (destArr.length === 0) { isOperationRunning=false; messageDialog.msg = "Please select a destination."; messageDialog.isError = true; messageDialog.open(); return } 
        if (operationsView.destPathText === "") { isOperationRunning=false; messageDialog.msg = "Enter destination path."; messageDialog.isError = true; messageDialog.open(); return } 
        backend.perform_batch_copy(JSON.stringify(filesArr), JSON.stringify(destArr), operationsView.destPathText, operationsView.userText, operationsView.passText, operationsView.authChecked ? "true" : "false", operationsView.svcListText, operationsView.stopBeforeChecked ? "true" : "false", operationsView.startAfterChecked ? "true" : "false", operationsView.msgAfterChecked ? "true" : "false", operationsView.msgBodyText) 
    }

    function startDeleteOperation() {
        resetOperationStats();
        var filesArr = getFilesArray(); var destArr = getDestArray();
        if (filesArr.length === 0) { isOperationRunning=false; messageDialog.msg = "Select files to delete."; messageDialog.isError = true; messageDialog.open(); return }
        if (destArr.length === 0) { isOperationRunning=false; messageDialog.msg = "Select destination."; messageDialog.isError = true; messageDialog.open(); return }
        if (operationsView.destPathText === "") { isOperationRunning=false; messageDialog.msg = "Enter remote path."; messageDialog.isError = true; messageDialog.open(); return }
        backend.perform_batch_delete(JSON.stringify(filesArr), JSON.stringify(destArr), operationsView.destPathText, operationsView.userText, operationsView.passText, operationsView.authChecked ? "true" : "false", operationsView.svcListText, operationsView.stopBeforeChecked ? "true" : "false", operationsView.startAfterChecked ? "true" : "false", operationsView.msgAfterChecked ? "true" : "false", operationsView.msgBodyText)
    }

    function startReplaceOperation() {
        resetOperationStats();
        var filesArr = getFilesArray(); var destArr = getDestArray();
        if (filesArr.length === 0) { isOperationRunning=false; messageDialog.msg = "Select files to replace."; messageDialog.isError = true; messageDialog.open(); return }
        if (destArr.length === 0) { isOperationRunning=false; messageDialog.msg = "Select destination."; messageDialog.isError = true; messageDialog.open(); return }
        if (operationsView.destPathText === "") { isOperationRunning=false; messageDialog.msg = "Enter remote path."; messageDialog.isError = true; messageDialog.open(); return }
        if (operationsView.replacePrefixText === "") { isOperationRunning=false; messageDialog.msg = "Enter a Prefix."; messageDialog.isError = true; messageDialog.open(); return }
        backend.perform_batch_replace(JSON.stringify(filesArr), JSON.stringify(destArr), operationsView.destPathText, operationsView.replacePrefixText, operationsView.userText, operationsView.passText, operationsView.authChecked ? "true" : "false", operationsView.svcListText, operationsView.stopBeforeChecked ? "true" : "false", operationsView.startAfterChecked ? "true" : "false", operationsView.msgAfterChecked ? "true" : "false", operationsView.msgBodyText)
    }

    function startRenameOperation() {
        resetOperationStats();
        var filesArr = getFilesArray(); var destArr = getDestArray();
        if (filesArr.length === 0) { isOperationRunning=false; messageDialog.msg = "Select files to rename."; messageDialog.isError = true; messageDialog.open(); return }
        if (destArr.length === 0) { isOperationRunning=false; messageDialog.msg = "Select destination."; messageDialog.isError = true; messageDialog.open(); return }
        if (operationsView.destPathText === "") { isOperationRunning=false; messageDialog.msg = "Enter remote path."; messageDialog.isError = true; messageDialog.open(); return }
        if (operationsView.renTagText === "") { isOperationRunning=false; messageDialog.msg = "Enter a tag."; messageDialog.isError = true; messageDialog.open(); return }
        var mode = operationsView.renPrefixChecked ? "prefix" : "suffix";
        backend.perform_batch_rename(JSON.stringify(filesArr), JSON.stringify(destArr), operationsView.destPathText, operationsView.renTagText, mode, operationsView.userText, operationsView.passText, operationsView.authChecked ? "true" : "false", operationsView.svcListText, operationsView.stopBeforeChecked ? "true" : "false", operationsView.startAfterChecked ? "true" : "false", operationsView.msgAfterChecked ? "true" : "false", operationsView.msgBodyText)
    }

    function startSingleRenameOperation() {
        resetOperationStats();
        var destArr = getDestArray();
        if (destArr.length === 0) { isOperationRunning=false; messageDialog.msg = "Select destination."; messageDialog.isError = true; messageDialog.open(); return }
        if (operationsView.destPathText === "") { isOperationRunning=false; messageDialog.msg = "Enter remote path."; messageDialog.isError = true; messageDialog.open(); return }
        if (operationsView.renOldText === "" || operationsView.renNewText === "") { isOperationRunning=false; messageDialog.msg = "Enter Old and New Names."; messageDialog.isError = true; messageDialog.open(); return }
        backend.perform_single_rename(JSON.stringify(destArr), operationsView.destPathText, operationsView.renOldText, operationsView.renNewText, operationsView.userText, operationsView.passText, operationsView.authChecked ? "true" : "false")
    }

    function startServiceStop() {
        resetOperationStats();
        var destArr = getDestArray();
        if (destArr.length === 0) { isOperationRunning=false; messageDialog.msg = "Select destination."; messageDialog.isError = true; messageDialog.open(); return }
        if (operationsView.svcActionText === "") { isOperationRunning=false; messageDialog.msg = "Enter Service Name."; messageDialog.isError = true; messageDialog.open(); return }
        backend.perform_service_control(JSON.stringify(destArr), operationsView.svcActionText, "stop", operationsView.userText, operationsView.passText, operationsView.authChecked ? "true" : "false")
    }

    function startServiceStart() {
        resetOperationStats();
        var destArr = getDestArray();
        if (destArr.length === 0) { isOperationRunning=false; messageDialog.msg = "Select destination."; messageDialog.isError = true; messageDialog.open(); return }
        if (operationsView.svcActionText === "") { isOperationRunning=false; messageDialog.msg = "Enter Service Name."; messageDialog.isError = true; messageDialog.open(); return }
        backend.perform_service_control(JSON.stringify(destArr), operationsView.svcActionText, "start", operationsView.userText, operationsView.passText, operationsView.authChecked ? "true" : "false")
    }

    function startSendMessage() {
        resetOperationStats();
        var destArr = getDestArray();
        if (destArr.length === 0) { isOperationRunning=false; messageDialog.msg = "Select destination."; messageDialog.isError = true; messageDialog.open(); return }
        if (operationsView.msgBodyText === "") { isOperationRunning=false; messageDialog.msg = "Enter message."; messageDialog.isError = true; messageDialog.open(); return }
        backend.perform_send_message(JSON.stringify(destArr), operationsView.msgBodyText, operationsView.userText, operationsView.passText, operationsView.authChecked ? "true" : "false")
    }

    // --- Helpers (بدون تغییر) ---
    function getDestArray() { var destArr = []; for(var d=0; d < destinationsModel.count; d++) { var dist = destinationsModel.get(d); for(var b=0; b < dist.branches.count; b++) { var branch = dist.branches.get(b); for(var s=0; s < branch.systems.count; s++) { var sys = branch.systems.get(s); if(sys.checked) destArr.push({"name": sys.sysName, "ip": sys.sysIp}) } } } return destArr }
    function getFilesArray() { var filesArr = []; for(var f=0; f < filesModel.count; f++) filesArr.push(filesModel.get(f).filePath); return filesArr }
    function checkAndAddFile(name, path, type) { for(var i=0; i < filesModel.count; i++) { if (filesModel.get(i).fileName === name) { dupDialog.dupName = name; dupDialog.dupType = type; dupDialog.open(); return } } filesModel.append({"fileName": name, "filePath": path, "fileType": type}) }
    function openFileBrowser(folderMode) { window.browseFolderMode = folderMode; var quick = JSON.parse(backend.get_quick_access()); quickAccessModel.clear(); for(var i=0; i<quick.length; i++) quickAccessModel.append(quick[i]); if(window.currentBrowsePath === "") window.currentBrowsePath = backend.get_home_dir(); refreshDir(window.currentBrowsePath); filePickerDialog.open() }
    function refreshDir(path) { window.currentBrowsePath = path; var items = JSON.parse(backend.list_dir(path)); dirModel.clear(); for(var i=0; i<items.length; i++) { items[i].checked = false; dirModel.append(items[i]) } }
    function addSelectedFiles() { var added = false; for(var i=0; i<dirModel.count; i++) { var item = dirModel.get(i); if (item.checked) { if (window.browseFolderMode && item.type === "Folder") { checkAndAddFile(item.name, item.path, "Folder"); added = true } else if (!window.browseFolderMode && item.type === "File") { checkAndAddFile(item.name, item.path, "File"); added = true } } } if (added) filePickerDialog.close() }
    function internalAddSystem(model, branch, type, name, ip) { var found = -1; for(var i=0; i < model.count; i++) { if(model.get(i).branchName === branch) { found = i; break } } if (found === -1) { model.append({"branchName": branch, "systems": []}); found = model.count - 1 } var sysList = model.get(found).systems; sysList.append({"sysName": name, "sysType": type, "sysIp": ip, "statusColor": c_bg_panel.toString()}) }
    function updateSystemStatus(branch, name, color) { for(var i=0; i < branchesModel.count; i++) { if(branchesModel.get(i).branchName === branch) { var systems = branchesModel.get(i).systems; for(var j=0; j < systems.count; j++) { if(systems.get(j).sysName === name) { systems.setProperty(j, "statusColor", color); return } } } } }
    function resetSystemStatus() { for(var i=0; i < branchesModel.count; i++) { var systems = branchesModel.get(i).systems; for(var j=0; j < systems.count; j++) { systems.setProperty(j, "statusColor", c_bg_panel.toString()) } } }
    
    function openAddDialog() { addSysDialog.isEditMode = false; addSysDialog.branchText = ""; addSysDialog.nameText = ""; addSysDialog.ipText = ""; addSysDialog.typeIndex = 4; addSysDialog.open() }
    function openEditDialog(bIdx, sIdx, branch, name, ip, type) { addSysDialog.isEditMode = true; addSysDialog.editBranchIndex = bIdx; addSysDialog.editSysIndex = sIdx; addSysDialog.branchText = branch; addSysDialog.nameText = name; addSysDialog.ipText = ip; for(var i=0; i<typeModel.count; i++) if(typeModel.get(i).text === type) { addSysDialog.typeIndex = i; break }; addSysDialog.open() }
    function saveSystem(branch, type, name, ip) { if (addSysDialog.isEditMode) { var bIdx = addSysDialog.editBranchIndex; var sIdx = addSysDialog.editSysIndex; var oldBranch = branchesModel.get(bIdx).branchName; var oldName = branchesModel.get(bIdx).systems.get(sIdx).sysName; var oldIp = branchesModel.get(bIdx).systems.get(sIdx).sysIp; backend.del_monitor_sys(oldBranch, oldName, oldIp); branchesModel.get(bIdx).systems.remove(sIdx); if (branchesModel.get(bIdx).systems.count === 0) branchesModel.remove(bIdx) } internalAddSystem(branchesModel, branch, type, name, ip); backend.add_monitor_sys(branch, type, name, ip) }
    function deleteSystem(bIndex, sIndex) { var branchObj = branchesModel.get(bIndex); var sysObj = branchObj.systems.get(sIndex); backend.del_monitor_sys(branchObj.branchName, sysObj.sysName, sysObj.sysIp); branchObj.systems.remove(sIndex); if (branchObj.systems.count === 0) branchesModel.remove(bIndex) }
    
    function openDestDialog() { destinationsDialog.isEditMode = false; destinationsDialog.destDistrictText = ""; destinationsDialog.destBranchText = ""; destinationsDialog.destNameText = ""; destinationsDialog.destIpText = ""; destinationsDialog.open() }
    function openDestEditDialog(dIndex, bIndex, sIndex, dist, branch, name, ip) { destinationsDialog.isEditMode = true; destinationsDialog.editDistIdx = dIndex; destinationsDialog.editBranchIdx = bIndex; destinationsDialog.editSysIdx = sIndex; destinationsDialog.destDistrictText = dist; destinationsDialog.destBranchText = branch; destinationsDialog.destNameText = name; destinationsDialog.destIpText = ip; destinationsDialog.open() }
    function saveDestination(district, branch, name, ip) { if (destinationsDialog.isEditMode) { var d = destinationsDialog.editDistIdx; var b = destinationsDialog.editBranchIdx; var s = destinationsDialog.editSysIdx; var oldDist = destinationsModel.get(d).districtName; var oldBranch = destinationsModel.get(d).branches.get(b).branchName; var oldName = destinationsModel.get(d).branches.get(b).systems.get(s).sysName; var oldIp = destinationsModel.get(d).branches.get(b).systems.get(s).sysIp; backend.del_dest_sys(oldDist, oldBranch, oldName, oldIp); var branchObj = destinationsModel.get(d).branches.get(b); branchObj.systems.remove(s); destinationsDialog.isEditMode = false } var foundDist = -1; for(var i=0; i<destinationsModel.count; i++) if(destinationsModel.get(i).districtName === district) { foundDist = i; break } if (foundDist === -1) { destinationsModel.append({ "districtName": district, "checked": false, "branches": [] }); foundDist = destinationsModel.count - 1 } var distObj = destinationsModel.get(foundDist); var foundBranch = -1; for(var j=0; j<distObj.branches.count; j++) if(distObj.branches.get(j).branchName === branch) { foundBranch = j; break } if (foundBranch === -1) { distObj.branches.append({ "branchName": branch, "checked": false, "systems": [] }); foundBranch = distObj.branches.count - 1 } var branchObjNew = distObj.branches.get(foundBranch); branchObjNew.systems.append({ "sysName": name, "sysType": "Client", "sysIp": ip, "checked": false }); backend.add_dest_sys(district, branch, name, ip) }
    function deleteDestination(dIndex, bIndex, sIndex) { var distName = destinationsModel.get(dIndex).districtName; var branchObj = destinationsModel.get(dIndex).branches.get(bIndex); var sysObj = branchObj.systems.get(sIndex); backend.del_dest_sys(distName, branchObj.branchName, sysObj.sysName, sysObj.sysIp); branchObj.systems.remove(sIndex) }
    function toggleDistrict(dIndex, state) { var d = destinationsModel.get(dIndex); d.checked = state; for(var i=0; i<d.branches.count; i++) toggleBranch(dIndex, i, state) }
    function toggleBranch(dIndex, bIndex, state) { var b = destinationsModel.get(dIndex).branches.get(bIndex); b.checked = state; for(var i=0; i<b.systems.count; i++) b.systems.setProperty(i, "checked", state) }
    function toggleAllDestinations(state) { for(var i=0; i<destinationsModel.count; i++) toggleDistrict(i, state); destinationsDialog.selectAllChecked = state }

    // --- MAIN LAYOUT ---
    Rectangle {
        id: mainBg
        anchors.fill: parent
        color: Theme.bg_input
        radius: 10
        border.color: Theme.border
        border.width: 2 
        clip: true 

        TitleBar { id: titleBar; windowRef: window; anchors.top: parent.top }

        Item {
            anchors.top: titleBar.bottom; anchors.bottom: parent.bottom; anchors.left: parent.left; anchors.right: parent.right; anchors.margins: 10
            
            MonitoringView {
                id: monitoringView
                width: 420; height: parent.height
                anchors.left: parent.left
                
                branchesModel: branchesModel
                isMonitoringActive: isMonitoringActive
                
                // --- FIX: استفاده از window. برای خواندن مقادیر صحیح ---
                totalCount: window.totalCount
                onlineCount: window.onlineCount
                offlineCount: window.offlineCount
                // -----------------------------------------------------
                
                onRequestAddSystem: openAddDialog()
                onRequestEditSystem: (bIdx, sIdx, branch, name, ip, type) => openEditDialog(bIdx, sIdx, branch, name, ip, type)
                onRequestDeleteSystem: (bIdx, sIdx) => deleteSystem(bIdx, sIdx)
            }

            OperationsView {
                id: operationsView
                width: 420; height: parent.height; anchors.left: monitoringView.right; anchors.leftMargin: 10
                filesModel: filesModel
                onRequestOpenFileBrowser: (isFolder) => openFileBrowser(isFolder)
                onRequestOpenDestDialog: openDestDialog()
                onRequestStartCopy: startCopyOperation()
                onRequestStartDelete: startDeleteOperation()
                onRequestStartReplace: startReplaceOperation()
                onRequestStartRename: startRenameOperation()
                onRequestStartSingleRename: startSingleRenameOperation()
                onRequestStartServiceStop: startServiceStop()
                onRequestStartServiceStart: startServiceStart()
                onRequestStartSendMessage: startSendMessage()
            }

            DetailsView {
                id: detailsView
                width: 420; height: parent.height
                anchors.left: operationsView.right; anchors.leftMargin: 10
                
                logModel: logModel
                opProgressValue: window.currentProgress
                
                // --- FIX: استفاده از window. برای حل مشکل 0 ماندن اعداد ---
                opTotal: window.opTotal
                opSuccess: window.opSuccess
                opWarning: window.opWarning
                opError: window.opError
                // --------------------------------------------------------
                
                onRequestOpenAboutDialog: aboutDialog.open()
            }
        }
    }

    // --- DIALOGS (بدون تغییر) ---
    DupDialog { id: dupDialog; onOkClicked: function(isFolder) { openFileBrowser(isFolder) } }
    MessageDialog { id: messageDialog }
    ErrorReportDialog { id: errorReportDialog; model: errorReportModel }
    FilePickerDialog { id: filePickerDialog; browseFolderMode: window.browseFolderMode; currentBrowsePath: window.currentBrowsePath; quickAccessModel: quickAccessModel; dirModel: dirModel; onRefreshDir: function(path) { refreshDir(path) }; onAddSelected: addSelectedFiles }
    AddSysDialog { id: addSysDialog; typeModel: typeModel; onSave: function(branch, type, name, ip) { saveSystem(branch, type, name, ip) } }
    DestinationsDialog { id: destinationsDialog; destinationsModel: destinationsModel; onSaveDest: function(d,b,n,i) { saveDestination(d,b,n,i); updateSelectionCount() }; onUpdateCount: updateSelectionCount; onOpenEdit: openDestEditDialog; onDeleteDest: function(d,b,s) { deleteDestination(d,b,s); updateSelectionCount() }; onToggleBranch: toggleBranch; onToggleAll: function(state) { toggleAllDestinations(state); updateSelectionCount() }; onClearSelection: function() { toggleAllDestinations(false); destinationsDialog.selectAllChecked = false; updateSelectionCount() } }
    AboutDialog { id: aboutDialog }
}