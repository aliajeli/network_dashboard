import subprocess
import os


class AuthHelper:
    """
    Helper class to manage Windows Network Authentication (IPC$).
    """

    @staticmethod
    def connect(ip, username, password, use_auth, signal):
        # تلاش برای اتصال با یوزر/پسورد اگر تیک زده شده باشد
        if use_auth:
            signal.emit(f"[{ip}] Authenticating...", "#d8dee9")
            try:
                cmd = f"net use \\\\{ip}\\IPC$ /user:{username} {password}"
                subprocess.check_call(
                    cmd,
                    shell=True,
                    stdout=subprocess.DEVNULL,
                    stderr=subprocess.DEVNULL,
                )
                signal.emit(f"[{ip}] Auth Success.", "#a3be8c")
                return True, True
            except:
                signal.emit(f"[{ip}] Auth failed. Trying anonymous...", "#d08770")

        # تلاش برای اتصال ناشناس (بدون پسورد)
        try:
            cmd = f'net use \\\\{ip}\\IPC$ "" /user:""'
            subprocess.check_call(
                cmd, shell=True, stdout=subprocess.DEVNULL, stderr=subprocess.DEVNULL
            )
            signal.emit(f"[{ip}] Connected anonymously.", "#a3be8c")
            return True, True
        except:
            # بررسی اینکه شاید قبلاً وصل بوده
            if os.path.exists(f"\\\\{ip}\\IPC$"):
                return True, False
            signal.emit(f"[{ip}] Connection Failed.", "#bf616a")
            return False, False

    @staticmethod
    def disconnect(ip, mounted):
        # قطع اتصال شبکه برای جلوگیری از تداخل در آینده
        if mounted:
            subprocess.run(
                f"net use \\\\{ip}\\IPC$ /delete",
                shell=True,
                stdout=subprocess.DEVNULL,
                stderr=subprocess.DEVNULL,
            )
