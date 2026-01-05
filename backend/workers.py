import os
import shutil
import time
import subprocess
import json
import re  # <--- این خط برای تحلیل پینگ لازم است
from concurrent.futures import ThreadPoolExecutor  # <--- این خط فراموش شده بود
from PyQt6.QtCore import QThread, pyqtSignal
from backend.auth import AuthHelper

# کلاس پایه برای جلوگیری از تکرار کد (اختیاری است اما برای تمیزی بهتر است)
# اما طبق دستور "کد تغییر نکند"، من همان کلاس‌ها را دقیقاً کپی می‌کنم.


class CopyWorker(QThread):
    progressSignal = pyqtSignal(str, str)
    statsSignal = pyqtSignal(int, int, int)
    finishedSignal = pyqtSignal(str)

    def __init__(
        self,
        file_list,
        dest_list,
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
        super().__init__()
        self.file_list = file_list
        self.dest_list = dest_list
        self.target_path = target_path
        self.username = username
        self.password = password
        self.use_auth = use_auth
        self.service_list = service_list
        self.stop_before = stop_before == "true"
        self.start_after = start_after == "true"
        self.send_msg = send_msg == "true"
        self.msg_text = msg_text

    def _control_services(self, ip, name, action):
        if not self.service_list:
            return
        services = [s.strip() for s in self.service_list.split(",")]
        for svc in services:
            if not svc:
                continue
            self.progressSignal.emit(
                f"[{name}] {action.capitalize()}ing service: {svc}...", "#d08770"
            )
            try:
                cmd = ["sc", f"\\\\{ip}", action, svc]
                flags = subprocess.CREATE_NO_WINDOW if os.name == "nt" else 0
                subprocess.run(
                    cmd,
                    stdout=subprocess.PIPE,
                    stderr=subprocess.PIPE,
                    creationflags=flags,
                )
                time.sleep(1)
            except:
                pass

    def _send_popup_msg(self, ip, name):
        if not self.msg_text:
            return
        try:
            cmd = ["msg", "*", "/server:" + ip, "/time:99999", self.msg_text]
            flags = subprocess.CREATE_NO_WINDOW if os.name == "nt" else 0
            subprocess.run(
                cmd, stdout=subprocess.PIPE, stderr=subprocess.PIPE, creationflags=flags
            )
            self.progressSignal.emit(f"[{name}] Message sent.", "#a3be8c")
        except:
            pass

    def run(self):
        error_report = []
        total = len(self.dest_list)
        success_systems = 0
        error_systems = 0
        self.statsSignal.emit(total, success_systems, error_systems)
        for dest in self.dest_list:
            ip = dest["ip"]
            name = dest["name"]
            system_has_error = False
            self.progressSignal.emit(
                f"--------------------------------------------------", "#4c566a"
            )
            self.progressSignal.emit(
                f"Processing System (COPY): {name} ({ip})", "#88c0d0"
            )
            if not self._ping(ip):
                self.progressSignal.emit(f"[{name}] Offline.", "#bf616a")
                error_systems += 1
                error_report.append({"name": name, "ip": ip, "reason": "Offline"})
                self.statsSignal.emit(total, success_systems, error_systems)
                continue
            is_connected, mounted = AuthHelper.connect(
                ip,
                self.username,
                self.password,
                self.use_auth == "true",
                self.progressSignal,
            )
            if not is_connected:
                error_systems += 1
                error_report.append({"name": name, "ip": ip, "reason": "Auth Failed"})
                self.statsSignal.emit(total, success_systems, error_systems)
                continue
            try:
                if self.stop_before:
                    self._control_services(ip, name, "stop")
                unc_target = self._get_unc_path(ip, self.target_path)
                if not os.path.exists(unc_target):
                    try:
                        os.makedirs(unc_target, exist_ok=True)
                    except Exception as e:
                        raise Exception(f"Cannot create dir: {str(e)}")
                for src_path in self.file_list:
                    base_name = os.path.basename(src_path)
                    final_dest = os.path.join(unc_target, base_name)
                    try:
                        if os.path.exists(final_dest):
                            raise Exception(f"File '{base_name}' exists.")
                        self.progressSignal.emit(
                            f"[{name}] Copying {base_name}...", "#d8dee9"
                        )
                        if os.path.isdir(src_path):
                            shutil.copytree(src_path, final_dest, dirs_exist_ok=True)
                        else:
                            shutil.copy2(src_path, final_dest)
                        self.progressSignal.emit(f"[{name}] Copied.", "#a3be8c")
                    except Exception as file_error:
                        system_has_error = True
                        self.progressSignal.emit(
                            f"[{name}] Error: {str(file_error)}", "#bf616a"
                        )
                        error_report.append(
                            {"name": name, "ip": ip, "reason": str(file_error)}
                        )
                if self.send_msg:
                    self._send_popup_msg(ip, name)
            except Exception as global_error:
                system_has_error = True
                self.progressSignal.emit(
                    f"[{name}] Critical: {str(global_error)}", "#bf616a"
                )
                error_report.append(
                    {"name": name, "ip": ip, "reason": str(global_error)}
                )
            finally:
                if self.start_after:
                    self._control_services(ip, name, "start")
                AuthHelper.disconnect(ip, mounted)
            if system_has_error:
                error_systems += 1
                self.progressSignal.emit(f"[{name}] Finished with errors.", "#d08770")
            else:
                success_systems += 1
                self.progressSignal.emit(f"[{name}] Success.", "#a3be8c")
            self.statsSignal.emit(total, success_systems, error_systems)
        self.finishedSignal.emit(json.dumps(error_report))

    def _ping(self, ip):
        param = "-n" if os.name == "nt" else "-c"
        flags = subprocess.CREATE_NO_WINDOW if os.name == "nt" else 0
        try:
            subprocess.check_call(
                ["ping", param, "1", "-w", "1000", ip],
                stdout=subprocess.DEVNULL,
                stderr=subprocess.DEVNULL,
                creationflags=flags,
            )
            return True
        except:
            return False

    def _get_unc_path(self, ip, path):
        if ":" in path:
            drive, tail = path.split(":", 1)
            return f"\\\\{ip}\\{drive}${tail}"
        if path.startswith("\\\\"):
            return path
        return f"\\\\{ip}\\{path}"


class DeleteWorker(QThread):
    progressSignal = pyqtSignal(str, str)
    statsSignal = pyqtSignal(int, int, int)
    finishedSignal = pyqtSignal(str)

    def __init__(
        self,
        file_list,
        dest_list,
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
        super().__init__()
        self.file_list = file_list
        self.dest_list = dest_list
        self.target_path = target_path
        self.username = username
        self.password = password
        self.use_auth = use_auth
        self.service_list = service_list
        self.stop_before = stop_before == "true"
        self.start_after = start_after == "true"
        self.send_msg = send_msg == "true"
        self.msg_text = msg_text

    def _control_services(self, ip, name, action):
        if not self.service_list:
            return
        services = [s.strip() for s in self.service_list.split(",")]
        for svc in services:
            if not svc:
                continue
            self.progressSignal.emit(
                f"[{name}] {action.capitalize()}ing service: {svc}...", "#d08770"
            )
            try:
                cmd = ["sc", f"\\\\{ip}", action, svc]
                flags = subprocess.CREATE_NO_WINDOW if os.name == "nt" else 0
                subprocess.run(
                    cmd,
                    stdout=subprocess.PIPE,
                    stderr=subprocess.PIPE,
                    creationflags=flags,
                )
                time.sleep(1)
            except:
                pass

    def _send_popup_msg(self, ip, name):
        if not self.msg_text:
            return
        try:
            cmd = ["msg", "*", "/server:" + ip, "/time:99999", self.msg_text]
            flags = subprocess.CREATE_NO_WINDOW if os.name == "nt" else 0
            subprocess.run(
                cmd, stdout=subprocess.PIPE, stderr=subprocess.PIPE, creationflags=flags
            )
            self.progressSignal.emit(f"[{name}] Message sent.", "#a3be8c")
        except:
            pass

    def run(self):
        error_report = []
        total = len(self.dest_list)
        success_systems = 0
        error_systems = 0
        self.statsSignal.emit(total, success_systems, error_systems)
        for dest in self.dest_list:
            ip = dest["ip"]
            name = dest["name"]
            system_has_error = False
            self.progressSignal.emit(
                f"--------------------------------------------------", "#4c566a"
            )
            self.progressSignal.emit(
                f"Processing System (DELETE): {name} ({ip})", "#88c0d0"
            )
            if not self._ping(ip):
                self.progressSignal.emit(f"[{name}] Offline.", "#bf616a")
                error_systems += 1
                error_report.append({"name": name, "ip": ip, "reason": "Offline"})
                self.statsSignal.emit(total, success_systems, error_systems)
                continue
            is_connected, mounted = AuthHelper.connect(
                ip,
                self.username,
                self.password,
                self.use_auth == "true",
                self.progressSignal,
            )
            if not is_connected:
                error_systems += 1
                error_report.append({"name": name, "ip": ip, "reason": "Auth Failed"})
                self.statsSignal.emit(total, success_systems, error_systems)
                continue
            try:
                if self.stop_before:
                    self._control_services(ip, name, "stop")
                unc_target = self._get_unc_path(ip, self.target_path)
                if not os.path.exists(unc_target):
                    raise Exception(f"Target folder not found")
                for src_path in self.file_list:
                    base_name = os.path.basename(src_path)
                    final_path = os.path.join(unc_target, base_name)
                    try:
                        if not os.path.exists(final_path):
                            raise Exception(f"'{base_name}' not found.")
                        self.progressSignal.emit(
                            f"[{name}] Deleting {base_name}...", "#d8dee9"
                        )
                        if os.path.isdir(final_path):
                            shutil.rmtree(final_path)
                        else:
                            os.remove(final_path)
                        self.progressSignal.emit(f"[{name}] Deleted.", "#a3be8c")
                    except Exception as file_error:
                        system_has_error = True
                        self.progressSignal.emit(
                            f"[{name}] Error: {str(file_error)}", "#bf616a"
                        )
                        error_report.append(
                            {"name": name, "ip": ip, "reason": str(file_error)}
                        )
                if self.send_msg:
                    self._send_popup_msg(ip, name)
            except Exception as global_error:
                system_has_error = True
                self.progressSignal.emit(
                    f"[{name}] Critical: {str(global_error)}", "#bf616a"
                )
                error_report.append(
                    {"name": name, "ip": ip, "reason": str(global_error)}
                )
            finally:
                if self.start_after:
                    self._control_services(ip, name, "start")
                AuthHelper.disconnect(ip, mounted)
            if system_has_error:
                error_systems += 1
                self.progressSignal.emit(f"[{name}] Failed.", "#d08770")
            else:
                success_systems += 1
                self.progressSignal.emit(f"[{name}] Success.", "#a3be8c")
            self.statsSignal.emit(total, success_systems, error_systems)
        self.finishedSignal.emit(json.dumps(error_report))

    def _ping(self, ip):
        param = "-n" if os.name == "nt" else "-c"
        flags = subprocess.CREATE_NO_WINDOW if os.name == "nt" else 0
        try:
            subprocess.check_call(
                ["ping", param, "1", "-w", "1000", ip],
                stdout=subprocess.DEVNULL,
                stderr=subprocess.DEVNULL,
                creationflags=flags,
            )
            return True
        except:
            return False

    def _get_unc_path(self, ip, path):
        if ":" in path:
            drive, tail = path.split(":", 1)
            return f"\\\\{ip}\\{drive}${tail}"
        if path.startswith("\\\\"):
            return path
        return f"\\\\{ip}\\{path}"


class ReplaceWorker(QThread):
    progressSignal = pyqtSignal(str, str)
    statsSignal = pyqtSignal(int, int, int)
    finishedSignal = pyqtSignal(str)

    def __init__(
        self,
        file_list,
        dest_list,
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
        super().__init__()
        self.file_list = file_list
        self.dest_list = dest_list
        self.target_path = target_path
        self.prefix = prefix
        self.username = username
        self.password = password
        self.use_auth = use_auth
        self.service_list = service_list
        self.stop_before = stop_before == "true"
        self.start_after = start_after == "true"
        self.send_msg = send_msg == "true"
        self.msg_text = msg_text

    def _control_services(self, ip, name, action):
        if not self.service_list:
            return
        services = [s.strip() for s in self.service_list.split(",")]
        for svc in services:
            if not svc:
                continue
            self.progressSignal.emit(
                f"[{name}] {action.capitalize()}ing service: {svc}...", "#d08770"
            )
            try:
                cmd = ["sc", f"\\\\{ip}", action, svc]
                flags = subprocess.CREATE_NO_WINDOW if os.name == "nt" else 0
                subprocess.run(
                    cmd,
                    stdout=subprocess.PIPE,
                    stderr=subprocess.PIPE,
                    creationflags=flags,
                )
                time.sleep(1)
            except:
                pass

    def _send_popup_msg(self, ip, name):
        if not self.msg_text:
            return
        try:
            cmd = ["msg", "*", "/server:" + ip, "/time:99999", self.msg_text]
            flags = subprocess.CREATE_NO_WINDOW if os.name == "nt" else 0
            subprocess.run(
                cmd, stdout=subprocess.PIPE, stderr=subprocess.PIPE, creationflags=flags
            )
            self.progressSignal.emit(f"[{name}] Message sent.", "#a3be8c")
        except:
            pass

    def run(self):
        error_report = []
        total = len(self.dest_list)
        success_systems = 0
        error_systems = 0
        self.statsSignal.emit(total, success_systems, error_systems)
        for dest in self.dest_list:
            ip = dest["ip"]
            name = dest["name"]
            system_has_error = False
            self.progressSignal.emit(
                f"--------------------------------------------------", "#4c566a"
            )
            self.progressSignal.emit(
                f"Processing System (REPLACE): {name} ({ip})", "#88c0d0"
            )
            if not self._ping(ip):
                self.progressSignal.emit(f"[{name}] Offline.", "#bf616a")
                error_systems += 1
                error_report.append({"name": name, "ip": ip, "reason": "Offline"})
                self.statsSignal.emit(total, success_systems, error_systems)
                continue
            is_connected, mounted = AuthHelper.connect(
                ip,
                self.username,
                self.password,
                self.use_auth == "true",
                self.progressSignal,
            )
            if not is_connected:
                error_systems += 1
                error_report.append({"name": name, "ip": ip, "reason": "Auth Failed"})
                self.statsSignal.emit(total, success_systems, error_systems)
                continue
            try:
                if self.stop_before:
                    self._control_services(ip, name, "stop")
                unc_target = self._get_unc_path(ip, self.target_path)
                if not os.path.exists(unc_target):
                    raise Exception(f"Target folder not found")
                for src_path in self.file_list:
                    base_name = os.path.basename(src_path)
                    current_remote_path = os.path.join(unc_target, base_name)
                    renamed_name = f"{self.prefix}-{base_name}"
                    renamed_remote_path = os.path.join(unc_target, renamed_name)
                    try:
                        if os.path.exists(current_remote_path):
                            if os.path.exists(renamed_remote_path):
                                raise Exception(f"Backup '{renamed_name}' exists.")
                            self.progressSignal.emit(
                                f"[{name}] Renaming {base_name}...", "#d8dee9"
                            )
                            os.rename(current_remote_path, renamed_remote_path)
                            self.progressSignal.emit(f"[{name}] Renamed.", "#a3be8c")
                        else:
                            self.progressSignal.emit(
                                f"[{name}] Original missing, skipping rename.",
                                "#d08770",
                            )
                        self.progressSignal.emit(
                            f"[{name}] Copying new {base_name}...", "#d8dee9"
                        )
                        if os.path.isdir(src_path):
                            shutil.copytree(
                                src_path, current_remote_path, dirs_exist_ok=True
                            )
                        else:
                            shutil.copy2(src_path, current_remote_path)
                        self.progressSignal.emit(
                            f"[{name}] Replaced successfully.", "#a3be8c"
                        )
                    except Exception as file_error:
                        system_has_error = True
                        self.progressSignal.emit(
                            f"[{name}] Error: {str(file_error)}", "#bf616a"
                        )
                        error_report.append(
                            {"name": name, "ip": ip, "reason": str(file_error)}
                        )
                if self.send_msg:
                    self._send_popup_msg(ip, name)
            except Exception as global_error:
                system_has_error = True
                self.progressSignal.emit(
                    f"[{name}] Critical: {str(global_error)}", "#bf616a"
                )
                error_report.append(
                    {"name": name, "ip": ip, "reason": str(global_error)}
                )
            finally:
                if self.start_after:
                    self._control_services(ip, name, "start")
                AuthHelper.disconnect(ip, mounted)
            if system_has_error:
                error_systems += 1
                self.progressSignal.emit(f"[{name}] Failed.", "#d08770")
            else:
                success_systems += 1
                self.progressSignal.emit(f"[{name}] Completed.", "#a3be8c")
            self.statsSignal.emit(total, success_systems, error_systems)
        self.finishedSignal.emit(json.dumps(error_report))

    def _ping(self, ip):
        param = "-n" if os.name == "nt" else "-c"
        flags = subprocess.CREATE_NO_WINDOW if os.name == "nt" else 0
        try:
            subprocess.check_call(
                ["ping", param, "1", "-w", "1000", ip],
                stdout=subprocess.DEVNULL,
                stderr=subprocess.DEVNULL,
                creationflags=flags,
            )
            return True
        except:
            return False

    def _get_unc_path(self, ip, path):
        if ":" in path:
            drive, tail = path.split(":", 1)
            return f"\\\\{ip}\\{drive}${tail}"
        if path.startswith("\\\\"):
            return path
        return f"\\\\{ip}\\{path}"


class RenameWorker(QThread):
    progressSignal = pyqtSignal(str, str)
    statsSignal = pyqtSignal(int, int, int)
    finishedSignal = pyqtSignal(str)

    def __init__(
        self,
        file_list,
        dest_list,
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
        super().__init__()
        self.file_list = file_list
        self.dest_list = dest_list
        self.target_path = target_path
        self.tag = tag
        self.mode = mode
        self.username = username
        self.password = password
        self.use_auth = use_auth
        self.service_list = service_list
        self.stop_before = stop_before == "true"
        self.start_after = start_after == "true"
        self.send_msg = send_msg == "true"
        self.msg_text = msg_text

    def _control_services(self, ip, name, action):
        if not self.service_list:
            return
        services = [s.strip() for s in self.service_list.split(",")]
        for svc in services:
            if not svc:
                continue
            self.progressSignal.emit(
                f"[{name}] {action.capitalize()}ing service: {svc}...", "#d08770"
            )
            try:
                cmd = ["sc", f"\\\\{ip}", action, svc]
                flags = subprocess.CREATE_NO_WINDOW if os.name == "nt" else 0
                subprocess.run(
                    cmd,
                    stdout=subprocess.PIPE,
                    stderr=subprocess.PIPE,
                    creationflags=flags,
                )
                time.sleep(1)
            except:
                pass

    def _send_popup_msg(self, ip, name):
        if not self.msg_text:
            return
        try:
            cmd = ["msg", "*", "/server:" + ip, "/time:99999", self.msg_text]
            flags = subprocess.CREATE_NO_WINDOW if os.name == "nt" else 0
            subprocess.run(
                cmd, stdout=subprocess.PIPE, stderr=subprocess.PIPE, creationflags=flags
            )
            self.progressSignal.emit(f"[{name}] Message sent.", "#a3be8c")
        except:
            pass

    def run(self):
        error_report = []
        total = len(self.dest_list)
        success_systems = 0
        error_systems = 0
        self.statsSignal.emit(total, success_systems, error_systems)
        for dest in self.dest_list:
            ip = dest["ip"]
            name = dest["name"]
            system_has_error = False
            self.progressSignal.emit(
                f"--------------------------------------------------", "#4c566a"
            )
            self.progressSignal.emit(
                f"Processing System (RENAME): {name} ({ip})", "#88c0d0"
            )
            if not self._ping(ip):
                self.progressSignal.emit(f"[{name}] Offline.", "#bf616a")
                error_systems += 1
                error_report.append({"name": name, "ip": ip, "reason": "Offline"})
                self.statsSignal.emit(total, success_systems, error_systems)
                continue
            is_connected, mounted = AuthHelper.connect(
                ip,
                self.username,
                self.password,
                self.use_auth == "true",
                self.progressSignal,
            )
            if not is_connected:
                error_systems += 1
                error_report.append({"name": name, "ip": ip, "reason": "Auth Failed"})
                self.statsSignal.emit(total, success_systems, error_systems)
                continue
            try:
                if self.stop_before:
                    self._control_services(ip, name, "stop")
                unc_target = self._get_unc_path(ip, self.target_path)
                if not os.path.exists(unc_target):
                    raise Exception(f"Target folder not found")
                for src_path in self.file_list:
                    base_name = os.path.basename(src_path)
                    current_remote_path = os.path.join(unc_target, base_name)
                    if self.mode == "prefix":
                        new_name = f"{self.tag}-{base_name}"
                    else:
                        name_part, ext = os.path.splitext(base_name)
                        new_name = f"{name_part}-{self.tag}{ext}"
                    new_remote_path = os.path.join(unc_target, new_name)
                    try:
                        if not os.path.exists(current_remote_path):
                            raise Exception(f"File '{base_name}' not found.")
                        if os.path.exists(new_remote_path):
                            raise Exception(f"Name '{new_name}' exists.")
                        self.progressSignal.emit(
                            f"[{name}] Renaming {base_name}...", "#d8dee9"
                        )
                        os.rename(current_remote_path, new_remote_path)
                        self.progressSignal.emit(f"[{name}] Success.", "#a3be8c")
                    except Exception as file_error:
                        system_has_error = True
                        self.progressSignal.emit(
                            f"[{name}] Error: {str(file_error)}", "#bf616a"
                        )
                        error_report.append(
                            {"name": name, "ip": ip, "reason": str(file_error)}
                        )
                if self.send_msg:
                    self._send_popup_msg(ip, name)
            except Exception as global_error:
                system_has_error = True
                self.progressSignal.emit(
                    f"[{name}] Critical: {str(global_error)}", "#bf616a"
                )
                error_report.append(
                    {"name": name, "ip": ip, "reason": str(global_error)}
                )
            finally:
                if self.start_after:
                    self._control_services(ip, name, "start")
                AuthHelper.disconnect(ip, mounted)
            if system_has_error:
                error_systems += 1
                self.progressSignal.emit(f"[{name}] Failed.", "#d08770")
            else:
                success_systems += 1
                self.progressSignal.emit(f"[{name}] Completed.", "#a3be8c")
            self.statsSignal.emit(total, success_systems, error_systems)
        self.finishedSignal.emit(json.dumps(error_report))

    def _ping(self, ip):
        param = "-n" if os.name == "nt" else "-c"
        flags = subprocess.CREATE_NO_WINDOW if os.name == "nt" else 0
        try:
            subprocess.check_call(
                ["ping", param, "1", "-w", "1000", ip],
                stdout=subprocess.DEVNULL,
                stderr=subprocess.DEVNULL,
                creationflags=flags,
            )
            return True
        except:
            return False

    def _get_unc_path(self, ip, path):
        if ":" in path:
            drive, tail = path.split(":", 1)
            return f"\\\\{ip}\\{drive}${tail}"
        if path.startswith("\\\\"):
            return path
        return f"\\\\{ip}\\{path}"


class SingleRenameWorker(QThread):
    progressSignal = pyqtSignal(str, str)
    statsSignal = pyqtSignal(int, int, int)
    finishedSignal = pyqtSignal(str)

    def __init__(
        self, dest_list, target_path, old_name, new_name, username, password, use_auth
    ):
        super().__init__()
        self.dest_list = dest_list
        self.target_path = target_path
        self.old_name = old_name
        self.new_name = new_name
        self.username = username
        self.password = password
        self.use_auth = use_auth

    def run(self):
        error_report = []
        total = len(self.dest_list)
        success_systems = 0
        error_systems = 0
        self.statsSignal.emit(total, success_systems, error_systems)
        for dest in self.dest_list:
            ip = dest["ip"]
            name = dest["name"]
            system_has_error = False
            self.progressSignal.emit(
                f"--------------------------------------------------", "#4c566a"
            )
            self.progressSignal.emit(
                f"Processing System (SINGLE RENAME): {name} ({ip})", "#88c0d0"
            )
            if not self._ping(ip):
                self.progressSignal.emit(f"[{name}] Offline.", "#bf616a")
                error_systems += 1
                error_report.append({"name": name, "ip": ip, "reason": "Offline"})
                self.statsSignal.emit(total, success_systems, error_systems)
                continue
            is_connected, mounted = AuthHelper.connect(
                ip,
                self.username,
                self.password,
                self.use_auth == "true",
                self.progressSignal,
            )
            if not is_connected:
                error_systems += 1
                error_report.append({"name": name, "ip": ip, "reason": "Auth Failed"})
                self.statsSignal.emit(total, success_systems, error_systems)
                continue
            try:
                unc_target = self._get_unc_path(ip, self.target_path)
                if not os.path.exists(unc_target):
                    raise Exception(f"Target folder not found")
                old_path = os.path.join(unc_target, self.old_name)
                new_path = os.path.join(unc_target, self.new_name)
                if not os.path.exists(old_path):
                    raise Exception(f"Source '{self.old_name}' not found.")
                if os.path.exists(new_path):
                    raise Exception(f"Target '{self.new_name}' exists.")
                self.progressSignal.emit(f"[{name}] Renaming...", "#d8dee9")
                os.rename(old_path, new_path)
                self.progressSignal.emit(f"[{name}] Success.", "#a3be8c")
            except Exception as e:
                system_has_error = True
                self.progressSignal.emit(f"[{name}] Error: {str(e)}", "#bf616a")
                error_report.append({"name": name, "ip": ip, "reason": str(e)})
            finally:
                AuthHelper.disconnect(ip, mounted)
            if system_has_error:
                error_systems += 1
                self.progressSignal.emit(f"[{name}] Failed.", "#d08770")
            else:
                success_systems += 1
                self.progressSignal.emit(f"[{name}] Done.", "#a3be8c")
            self.statsSignal.emit(total, success_systems, error_systems)
        self.finishedSignal.emit(json.dumps(error_report))

    def _ping(self, ip):
        param = "-n" if os.name == "nt" else "-c"
        flags = subprocess.CREATE_NO_WINDOW if os.name == "nt" else 0
        try:
            subprocess.check_call(
                ["ping", param, "1", "-w", "1000", ip],
                stdout=subprocess.DEVNULL,
                stderr=subprocess.DEVNULL,
                creationflags=flags,
            )
            return True
        except:
            return False

    def _get_unc_path(self, ip, path):
        if ":" in path:
            drive, tail = path.split(":", 1)
            return f"\\\\{ip}\\{drive}${tail}"
        if path.startswith("\\\\"):
            return path
        return f"\\\\{ip}\\{path}"


class ServiceWorker(QThread):
    progressSignal = pyqtSignal(str, str)
    statsSignal = pyqtSignal(int, int, int)
    finishedSignal = pyqtSignal(str)

    def __init__(self, dest_list, service_name, action, username, password, use_auth):
        super().__init__()
        self.dest_list = dest_list
        self.service_name = service_name
        self.action = action
        self.username = username
        self.password = password
        self.use_auth = use_auth

    def run(self):
        error_report = []
        total = len(self.dest_list)
        success_systems = 0
        error_systems = 0
        self.statsSignal.emit(total, success_systems, error_systems)
        for dest in self.dest_list:
            ip = dest["ip"]
            name = dest["name"]
            system_has_error = False
            self.progressSignal.emit(
                f"--------------------------------------------------", "#4c566a"
            )
            self.progressSignal.emit(
                f"Processing System (SERVICE {self.action.upper()}): {name} ({ip})",
                "#88c0d0",
            )
            if not self._ping(ip):
                self.progressSignal.emit(f"[{name}] Offline.", "#bf616a")
                error_systems += 1
                error_report.append({"name": name, "ip": ip, "reason": "Offline"})
                self.statsSignal.emit(total, success_systems, error_systems)
                continue
            is_connected, mounted = AuthHelper.connect(
                ip,
                self.username,
                self.password,
                self.use_auth == "true",
                self.progressSignal,
            )
            if not is_connected:
                error_systems += 1
                error_report.append({"name": name, "ip": ip, "reason": "Auth Failed"})
                self.statsSignal.emit(total, success_systems, error_systems)
                continue
            try:
                sc_cmd = ["sc", f"\\\\{ip}", self.action, self.service_name]
                self.progressSignal.emit(
                    f"[{name}] Sending {self.action} command...", "#d8dee9"
                )
                flags = subprocess.CREATE_NO_WINDOW if os.name == "nt" else 0
                result = subprocess.run(
                    sc_cmd,
                    stdout=subprocess.PIPE,
                    stderr=subprocess.PIPE,
                    creationflags=flags,
                )
                if result.returncode == 0:
                    self.progressSignal.emit(f"[{name}] Success.", "#a3be8c")
                else:
                    err_msg = result.stderr.decode().strip() or "Unknown Error"
                    try:
                        err_msg = result.stdout.decode().strip() + " " + err_msg
                    except:
                        pass
                    raise Exception(f"SC Error: {err_msg}")
            except Exception as e:
                system_has_error = True
                self.progressSignal.emit(f"[{name}] Error: {str(e)}", "#bf616a")
                error_report.append({"name": name, "ip": ip, "reason": str(e)})
            finally:
                AuthHelper.disconnect(ip, mounted)
            if system_has_error:
                error_systems += 1
                self.progressSignal.emit(f"[{name}] Failed.", "#d08770")
            else:
                success_systems += 1
                self.progressSignal.emit(f"[{name}] Success.", "#a3be8c")
            self.statsSignal.emit(total, success_systems, error_systems)
        self.finishedSignal.emit(json.dumps(error_report))

    def _ping(self, ip):
        param = "-n" if os.name == "nt" else "-c"
        flags = subprocess.CREATE_NO_WINDOW if os.name == "nt" else 0
        try:
            subprocess.check_call(
                ["ping", param, "1", "-w", "1000", ip],
                stdout=subprocess.DEVNULL,
                stderr=subprocess.DEVNULL,
                creationflags=flags,
            )
            return True
        except:
            return False


class MessageWorker(QThread):
    progressSignal = pyqtSignal(str, str)
    statsSignal = pyqtSignal(int, int, int)
    finishedSignal = pyqtSignal(str)

    def __init__(self, dest_list, message, username, password, use_auth):
        super().__init__()
        self.dest_list = dest_list
        self.message = message
        self.username = username
        self.password = password
        self.use_auth = use_auth

    def run(self):
        error_report = []
        total = len(self.dest_list)
        success_systems = 0
        error_systems = 0
        self.statsSignal.emit(total, success_systems, error_systems)
        for dest in self.dest_list:
            ip = dest["ip"]
            name = dest["name"]
            system_has_error = False
            self.progressSignal.emit(
                f"--------------------------------------------------", "#4c566a"
            )
            self.progressSignal.emit(
                f"Processing System (MESSAGE): {name} ({ip})", "#88c0d0"
            )
            if not self._ping(ip):
                self.progressSignal.emit(f"[{name}] Offline.", "#bf616a")
                error_systems += 1
                error_report.append({"name": name, "ip": ip, "reason": "Offline"})
                self.statsSignal.emit(total, success_systems, error_systems)
                continue
            is_connected, mounted = AuthHelper.connect(
                ip,
                self.username,
                self.password,
                self.use_auth == "true",
                self.progressSignal,
            )
            if not is_connected:
                error_systems += 1
                error_report.append({"name": name, "ip": ip, "reason": "Auth Failed"})
                self.statsSignal.emit(total, success_systems, error_systems)
                continue
            try:
                cmd = ["msg", "*", "/server:" + ip, "/time:99999", self.message]
                self.progressSignal.emit(f"[{name}] Sending message...", "#d8dee9")
                flags = subprocess.CREATE_NO_WINDOW if os.name == "nt" else 0
                result = subprocess.run(
                    cmd,
                    stdout=subprocess.PIPE,
                    stderr=subprocess.PIPE,
                    creationflags=flags,
                )
                if result.returncode == 0:
                    self.progressSignal.emit(f"[{name}] Sent.", "#a3be8c")
                else:
                    err_msg = (
                        result.stderr.decode().strip()
                        or "Msg failed (User not logged in?)"
                    )
                    raise Exception(f"{err_msg}")
            except Exception as e:
                system_has_error = True
                self.progressSignal.emit(f"[{name}] Error: {str(e)}", "#bf616a")
                error_report.append({"name": name, "ip": ip, "reason": str(e)})
            finally:
                AuthHelper.disconnect(ip, mounted)
            if system_has_error:
                error_systems += 1
                self.progressSignal.emit(f"[{name}] Failed.", "#d08770")
            else:
                success_systems += 1
                self.progressSignal.emit(f"[{name}] Success.", "#a3be8c")
            self.statsSignal.emit(total, success_systems, error_systems)
        self.finishedSignal.emit(json.dumps(error_report))

    def _ping(self, ip):
        param = "-n" if os.name == "nt" else "-c"
        flags = subprocess.CREATE_NO_WINDOW if os.name == "nt" else 0
        try:
            subprocess.check_call(
                ["ping", param, "1", "-w", "1000", ip],
                stdout=subprocess.DEVNULL,
                stderr=subprocess.DEVNULL,
                creationflags=flags,
            )
            return True
        except:
            return False


class MonitorWorker(QThread):
    # سیگنال برای ارسال نتیجه: (branch, name, color)
    updateSignal = pyqtSignal(str, str, str)
    statsSignal = pyqtSignal(int, int, int)

    def __init__(self, db_manager):
        super().__init__()
        self.db = db_manager
        self.running = True

    def run(self):
        C_GREEN = "#a3be8c"
        C_ORANGE = "#d08770"
        C_RED = "#bf616a"
        C_YELLOW = "#ebcb8b"

        while self.running:
            # دریافت لیست سیستم‌ها از دیتابیس
            # نکته: چون sqlite روی ترد دیگر است، بهتر است لیست را در bridge بگیریم و پاس بدهیم
            # اما اگر db_manager با check_same_thread=False ساخته شده باشد، اینجا هم کار میکند.
            try:
                systems = self.db.get_flat_monitoring_list()
            except:
                break  # اگر دیتابیس لاک بود یا ارور داد

            total = len(systems)
            online = 0
            offline = 0

            # استفاده از ThreadPool برای پینگ موازی
            with ThreadPoolExecutor(max_workers=30) as executor:
                # مپ کردن فیوچرها به اطلاعات سیستم
                futures = {
                    executor.submit(self._execute_ping, s[2]): s for s in systems
                }

                for f in futures:
                    if not self.running:
                        break
                    branch, name, ip = futures[f]
                    try:
                        is_up, ms = f.result()
                        col = C_RED
                        if is_up:
                            online += 1
                            if ms < 100:
                                col = C_GREEN
                            elif ms < 200:
                                col = C_YELLOW
                            elif ms < 400:
                                col = C_ORANGE
                            else:
                                col = C_RED
                        else:
                            offline += 1
                            col = C_RED

                        # ارسال سیگنال آپدیت به رابط کاربری
                        self.updateSignal.emit(branch, name, col)
                    except:
                        pass

            if self.running:
                self.statsSignal.emit(total, online, offline)
                # وقفه ۵ ثانیه‌ای (به صورت خرد شده برای واکنش سریع به توقف)
                for _ in range(50):
                    if not self.running:
                        break
                    time.sleep(0.1)

    def _execute_ping(self, ip):
        # تابع پینگ داخلی
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

    def stop(self):
        self.running = False
        self.wait()


class SystemInfoWorker(QThread):
    finishedSignal = pyqtSignal(str)

    def __init__(self, ip, username, password, is_local):
        super().__init__()
        self.ip = ip
        self.username = username.strip() if username else ""
        self.password = password if password else ""
        self.is_local = is_local

    def run(self):
        try:
            # اگر لوکال است، از دستورات ساده استفاده کن
            if self.is_local:
                self._run_local()
            else:
                self._run_remote()

        except Exception as e:
            self.finishedSignal.emit(json.dumps({"error": str(e)}))

    def _run_local(self):
        # اجرای ساده برای لوکال (بدون Credential)
        self._execute_ps("")

    def _run_remote(self):
        # ساخت Credential بلاک فقط اگر یوزر داریم
        cred_block = ""
        if self.username and self.password:
            # روش جدید: استفاده از CIM Option (بدون نیاز به SecureString)
            cred_block = f"""
            $secPass = ConvertTo-SecureString '{self.password}' -AsPlainText -Force
            $cred = New-Object System.Management.Automation.PSCredential ('{self.username}', $secPass)
            $cimOpt = New-CimSessionOption -Protocol DCOM
            $sess = New-CimSession -ComputerName '{self.ip}' -Credential $cred -SessionOption $cimOpt -ErrorAction Stop
            """
        else:
            # اتصال بدون پسورد (Current User)
            cred_block = (
                f"$sess = New-CimSession -ComputerName '{self.ip}' -ErrorAction Stop"
            )

        self._execute_ps(cred_block, use_session=True)

    def _execute_ps(self, setup_block, use_session=False):
        # اگر از سشن استفاده می‌کنیم، پارامتر دستور فرق می‌کند
        cmd_param = "-CimSession $sess" if use_session else ""

        ps_script = f"""
        $ErrorActionPreference = 'Stop'
        [Console]::OutputEncoding = [System.Text.Encoding]::UTF8
        
        try {{
            {setup_block}
            
            # 1. جمع‌آوری اطلاعات با CIM (پایدارتر از WMI Object)
            $os = Get-CimInstance Win32_OperatingSystem {cmd_param} | Select-Object Caption, Version, OSArchitecture, SerialNumber, CSName
            $cpu = Get-CimInstance Win32_Processor {cmd_param} | Select-Object Name, NumberOfCores
            $ram = Get-CimInstance Win32_ComputerSystem {cmd_param} | Select-Object TotalPhysicalMemory, Model, Manufacturer
            $disk = Get-CimInstance Win32_LogicalDisk {cmd_param} | Where-Object {{ $_.DriveType -eq 3 }} | Select-Object DeviceID, Size, FreeSpace
            $printers = Get-CimInstance Win32_Printer {cmd_param} | Select-Object Name, Default, PortName, DriverName, PrinterStatus

            # اگر سشن باز کردیم، ببندیمش
            if ($sess) {{ Remove-CimSession $sess }}

            $info = @{{
                _ComputerName = $os.CSName
                OS = $os
                CPU = $cpu
                RAM = $ram
                Disks = $disk
                Printers = $printers
            }}
            
            $info | ConvertTo-Json -Depth 2 -Compress

        }} catch {{
            $err = $_.Exception.Message
            $err = $err -replace '[\\r\\n]', ' ' -replace '"', "'"
            Write-Output "{{\\"error\\": \\"$err\\"}}"
        }}
        """

        flags = subprocess.CREATE_NO_WINDOW if os.name == "nt" else 0
        cmd = ["powershell", "-NoProfile", "-Command", ps_script]

        result = subprocess.run(
            cmd,
            capture_output=True,
            text=True,
            creationflags=flags,
            encoding="utf-8",
            timeout=25,
        )
        output = result.stdout.strip()

        if not output:
            err = result.stderr if result.stderr else "Empty response."
            self.finishedSignal.emit(json.dumps({"error": err}))
        elif not output.startswith("{"):
            self.finishedSignal.emit(json.dumps({"error": f"PS Error: {output}"}))
        else:
            self.finishedSignal.emit(output)
