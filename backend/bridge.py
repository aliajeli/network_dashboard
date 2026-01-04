import sys
import os
import time
import subprocess
import threading
import json
import re
from concurrent.futures import ThreadPoolExecutor
from PyQt6.QtCore import QObject, pyqtSlot, pyqtSignal, QStandardPaths, QStorageInfo
from PyQt6.QtWidgets import QFileDialog

from backend.database import DatabaseManager

# مطمئن شوید MonitorWorker هم ایمپورت شده است
from backend.workers import (
    CopyWorker,
    DeleteWorker,
    ReplaceWorker,
    RenameWorker,
    SingleRenameWorker,
    ServiceWorker,
    MessageWorker,
    MonitorWorker,
)


class Backend(QObject):
    logSignal = pyqtSignal(str, str)
    pingResultSignal = pyqtSignal(str)
    updateMonitorSignal = pyqtSignal(str, str, str)
    updateStatsSignal = pyqtSignal(int, int, int)  # مانیتورینگ
    opProgressSignal = pyqtSignal(int, int, int)  # عملیات
    resetMonitoringSignal = pyqtSignal()
    opFinishedSignal = pyqtSignal(str)
    fileAddedSignal = pyqtSignal(str, str, str)
    filesClearedSignal = pyqtSignal()

    def __init__(self):
        super().__init__()
        self.db = DatabaseManager()
        self.monitor_thread = None
        self.workers = []  # <--- ضروری برای جلوگیری از AttributeError

    def log(self, message, level="INFO"):
        color = "#4c566a"
        if level == "SUCCESS":
            color = "#a3be8c"
        elif level == "ERROR":
            color = "#bf616a"
        elif level == "WARN":
            color = "#d08770"
        self.logSignal.emit(f"{time.strftime('[%H:%M:%S]')} {message}", color)

    # ... (متدهای load_monitoring, load_destinations, add_... بدون تغییر) ...
    @pyqtSlot(result=str)
    def load_monitoring(self):
        systems = self.db.get_flat_monitoring_list()
        self.updateStatsSignal.emit(len(systems), -1, -1)
        return self.db.get_monitoring_data()

    @pyqtSlot(result=str)
    def load_destinations(self):
        return self.db.get_destination_data()

    @pyqtSlot(str, str, str, str)
    def add_monitor_sys(self, branch, type_, name, ip):
        self.db.add_monitoring(branch, name, type_, ip)
        self.log(f"Added Monitoring: {name}", "SUCCESS")
        systems = self.db.get_flat_monitoring_list()
        self.updateStatsSignal.emit(len(systems), -1, -1)

    @pyqtSlot(str, str, str)
    def del_monitor_sys(self, branch, name, ip):
        self.db.delete_monitoring(branch, name, ip)
        self.log(f"Deleted Monitoring: {name}", "WARN")
        systems = self.db.get_flat_monitoring_list()
        self.updateStatsSignal.emit(len(systems), -1, -1)

    @pyqtSlot(str, str, str, str)
    def add_dest_sys(self, district, branch, name, ip):
        self.db.add_destination(district, branch, name, ip)
        self.log(f"Added Destination: {name}", "SUCCESS")

    @pyqtSlot(str, str, str, str)
    def del_dest_sys(self, district, branch, name, ip):
        self.db.delete_destination(district, branch, name, ip)
        self.log(f"Deleted Destination: {name}", "WARN")

    @pyqtSlot(str)
    def run_ping(self, ip):
        if not ip:
            return
        self.log(f"Pinging {ip}...", "INFO")
        self.pingResultSignal.emit("Pinging...")
        threading.Thread(target=self._ping_thread, args=(ip,)).start()

    def _ping_thread(self, ip):
        res, ms = self._execute_ping(ip)
        if res:
            self.log(f"{ip} Online ({ms}ms)", "SUCCESS")
            self.pingResultSignal.emit("Online")
        else:
            self.log(f"{ip} Unreachable", "ERROR")
            self.pingResultSignal.emit("Offline")

    def _execute_ping(self, ip):
        param = "-n" if os.name == "nt" else "-c"
        flags = subprocess.CREATE_NO_WINDOW if os.name == "nt" else 0
        cmd = ["ping", param, "1", "-w", "1000", ip]
        try:
            out = subprocess.check_output(
                cmd, stderr=subprocess.STDOUT, creationflags=flags
            ).decode()
            match = re.search(r"time[=<]([\d\.]+)\s?ms", out, re.IGNORECASE)
            return True, float(match.group(1)) if match else 0
        except:
            return False, 0

    @pyqtSlot()
    def start_monitoring(self):
        if self.monitor_thread and self.monitor_thread.isRunning():
            return
        self.log("Monitoring Started.", "SUCCESS")
        self.monitor_thread = MonitorWorker(self.db)
        self.monitor_thread.updateSignal.connect(self.updateMonitorSignal)
        self.monitor_thread.statsSignal.connect(self.updateStatsSignal)
        self.monitor_thread.start()

    @pyqtSlot()
    def stop_monitoring(self):
        if self.monitor_thread:
            self.monitor_thread.stop()
            self.monitor_thread = None
        self.log("Monitoring Stopped.", "WARN")
        self.resetMonitoringSignal.emit()
        systems = self.db.get_flat_monitoring_list()
        self.updateStatsSignal.emit(len(systems), -1, -1)

    # ... (متدهای فایل سیستم: get_home_dir, list_dir, get_quick_access, clear_files بدون تغییر) ...
    @pyqtSlot(result=str)
    def get_home_dir(self):
        return os.path.expanduser("~").replace("\\", "/")

    @pyqtSlot(str, result=str)
    def list_dir(self, path):
        try:
            items = []
            parent = os.path.dirname(path)
            if len(path) > 3:
                items.append(
                    {"name": "..", "type": "Parent", "path": parent.replace("\\", "/")}
                )
            with os.scandir(path) as entries:
                for entry in entries:
                    try:
                        if entry.is_dir():
                            items.append(
                                {
                                    "name": entry.name,
                                    "type": "Folder",
                                    "path": entry.path.replace("\\", "/"),
                                }
                            )
                        else:
                            items.append(
                                {
                                    "name": entry.name,
                                    "type": "File",
                                    "path": entry.path.replace("\\", "/"),
                                }
                            )
                    except:
                        pass
            items.sort(
                key=lambda x: (
                    0 if x["type"] == "Parent" else 1 if x["type"] == "Folder" else 2,
                    x["name"].lower(),
                )
            )
            return json.dumps(items)
        except:
            return json.dumps([])

    @pyqtSlot(result=str)
    def get_quick_access(self):
        items = []
        locations = [
            ("Desktop", QStandardPaths.StandardLocation.DesktopLocation, "Desktop"),
            ("Documents", QStandardPaths.StandardLocation.DocumentsLocation, "Folder"),
            ("Downloads", QStandardPaths.StandardLocation.DownloadLocation, "Folder"),
            ("Pictures", QStandardPaths.StandardLocation.PicturesLocation, "Folder"),
            ("Music", QStandardPaths.StandardLocation.MusicLocation, "Folder"),
        ]
        for name, loc, icon in locations:
            path = QStandardPaths.writableLocation(loc).replace("\\", "/")
            if path:
                items.append(
                    {"name": name, "path": path, "type": "Quick", "iconType": icon}
                )
        for drive in QStorageInfo.mountedVolumes():
            name = drive.rootPath().replace("\\", "/")
            label = drive.displayName()
            display = f"{label} ({name})" if label else name
            items.append(
                {"name": display, "path": name, "type": "Drive", "iconType": "Drive"}
            )
        return json.dumps(items)

    @pyqtSlot()
    def clear_files(self):
        self.filesClearedSignal.emit()
        self.log("File list cleared.", "INFO")

    # ... (متدهای perform_batch_copy و غیره بدون تغییر) ...
    @pyqtSlot(str, str, str, str, str, str, str, str, str, str, str)
    def perform_batch_copy(
        self,
        files_json,
        dests_json,
        target_path,
        username,
        password,
        use_auth,
        service_list,
        stop_before,
        start_after,
        send_msg,
        msg_text,
    ):
        files = json.loads(files_json)
        dests = json.loads(dests_json)
        self.log(f"Starting COPY operation...", "INFO")
        w = CopyWorker(
            files,
            dests,
            target_path,
            username,
            password,
            use_auth,
            service_list,
            stop_before,
            start_after,
            send_msg,
            msg_text,
        )
        self._start_worker(w)

    @pyqtSlot(str, str, str, str, str, str, str, str, str, str, str)
    def perform_batch_delete(
        self,
        files_json,
        dests_json,
        target_path,
        username,
        password,
        use_auth,
        service_list,
        stop_before,
        start_after,
        send_msg,
        msg_text,
    ):
        files = json.loads(files_json)
        dests = json.loads(dests_json)
        self.log(f"Starting DELETE operation...", "INFO")
        w = DeleteWorker(
            files,
            dests,
            target_path,
            username,
            password,
            use_auth,
            service_list,
            stop_before,
            start_after,
            send_msg,
            msg_text,
        )
        self._start_worker(w)

    @pyqtSlot(str, str, str, str, str, str, str, str, str, str, str, str)
    def perform_batch_replace(
        self,
        files_json,
        dests_json,
        target_path,
        prefix,
        username,
        password,
        use_auth,
        service_list,
        stop_before,
        start_after,
        send_msg,
        msg_text,
    ):
        files = json.loads(files_json)
        dests = json.loads(dests_json)
        self.log(f"Starting REPLACE operation...", "INFO")
        w = ReplaceWorker(
            files,
            dests,
            target_path,
            prefix,
            username,
            password,
            use_auth,
            service_list,
            stop_before,
            start_after,
            send_msg,
            msg_text,
        )
        self._start_worker(w)

    @pyqtSlot(str, str, str, str, str, str, str, str, str, str, str, str, str)
    def perform_batch_rename(
        self,
        files_json,
        dests_json,
        target_path,
        tag,
        mode,
        username,
        password,
        use_auth,
        service_list,
        stop_before,
        start_after,
        send_msg,
        msg_text,
    ):
        files = json.loads(files_json)
        dests = json.loads(dests_json)
        self.log(f"Starting RENAME operation...", "INFO")
        w = RenameWorker(
            files,
            dests,
            target_path,
            tag,
            mode,
            username,
            password,
            use_auth,
            service_list,
            stop_before,
            start_after,
            send_msg,
            msg_text,
        )
        self._start_worker(w)

    @pyqtSlot(str, str, str, str, str, str, str)
    def perform_single_rename(
        self, dests_json, target_path, old_name, new_name, username, password, use_auth
    ):
        dests = json.loads(dests_json)
        self.log(f"Starting SINGLE RENAME...", "INFO")
        w = SingleRenameWorker(
            dests, target_path, old_name, new_name, username, password, use_auth
        )
        self._start_worker(w)

    @pyqtSlot(str, str, str, str, str, str)
    def perform_service_control(
        self, dests_json, service_name, action, username, password, use_auth
    ):
        dests = json.loads(dests_json)
        self.log(f"Starting SERVICE {action.upper()}...", "INFO")
        w = ServiceWorker(dests, service_name, action, username, password, use_auth)
        self._start_worker(w)

    @pyqtSlot(str, str, str, str, str)
    def perform_send_message(self, dests_json, message, username, password, use_auth):
        dests = json.loads(dests_json)
        self.log(f"Starting SEND MESSAGE...", "INFO")
        w = MessageWorker(dests, message, username, password, use_auth)
        self._start_worker(w)

    # ... (export_log_to_file بدون تغییر) ...
    @pyqtSlot(str)
    def export_log_to_file(self, log_content):
        file_path, _ = QFileDialog.getSaveFileName(
            None, "Export Log", "", "Text Files (*.txt);;All Files (*)"
        )
        if file_path:
            try:
                with open(file_path, "w", encoding="utf-8") as f:
                    f.write(log_content)
                self.log(f"Log exported to {file_path}", "SUCCESS")
            except Exception as e:
                self.log(f"Export failed: {str(e)}", "ERROR")

    # --- متد شروع ورکر (اصلاح شده) ---
    def _start_worker(self, worker):
        worker.progressSignal.connect(lambda msg, col: self.logSignal.emit(msg, col))
        worker.statsSignal.connect(lambda t, s, e: self.opProgressSignal.emit(t, s, e))
        worker.finishedSignal.connect(lambda err: self.opFinishedSignal.emit(err))

        # پاکسازی خودکار
        worker.finished.connect(lambda: self._cleanup_worker(worker))

        self.workers.append(worker)
        worker.start()

    def _cleanup_worker(self, worker):
        if worker in self.workers:
            self.workers.remove(worker)

    @pyqtSlot()
    def open_file_dialog(self):
        pass

    @pyqtSlot()
    def open_folder_dialog(self):
        pass

    # ... (بقیه توابع) ...

    @pyqtSlot(str, str)
    def remote_power_action(self, ip, action):
        """
        Executes remote shutdown or restart.
        action: 'shutdown' (-s) or 'restart' (-r)
        """
        if not ip:
            return

        switch = "-s" if action == "shutdown" else "-r"
        # -f = Force, -t 0 = Time 0, -m = Unc Path
        cmd = f"shutdown {switch} -f -t 0 -m \\\\{ip}"

        def run_cmd():
            try:
                # برای اجرای دستورات ریموت، شاید نیاز به احراز هویت قبلی باشد (net use)
                # اما فرض می‌کنیم دسترسی ادمین وجود دارد.
                subprocess.run(
                    cmd,
                    shell=True,
                    stdout=subprocess.DEVNULL,
                    stderr=subprocess.DEVNULL,
                )
                self.log(f"[{ip}] Sent {action} command.", "SUCCESS")
            except Exception as e:
                self.log(f"[{ip}] Failed to {action}: {str(e)}", "ERROR")

        self.log(f"[{ip}] Initiating {action}...", "WARN")
        threading.Thread(target=run_cmd).start()
