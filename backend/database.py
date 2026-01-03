import sqlite3
import json


class DatabaseManager:
    """
    Handles all SQLite operations for Monitoring and Destinations lists.
    """

    def __init__(self, db_name="dashboard.db"):
        self.conn = sqlite3.connect(db_name, check_same_thread=False)
        self.create_tables()

    def create_tables(self):
        cursor = self.conn.cursor()
        cursor.execute(
            """CREATE TABLE IF NOT EXISTS monitoring (id INTEGER PRIMARY KEY AUTOINCREMENT, branch TEXT, name TEXT, type TEXT, ip TEXT)"""
        )
        cursor.execute(
            """CREATE TABLE IF NOT EXISTS destinations (id INTEGER PRIMARY KEY AUTOINCREMENT, district TEXT, branch TEXT, name TEXT, ip TEXT)"""
        )
        self.conn.commit()

    def add_monitoring(self, branch, name, type_, ip):
        cursor = self.conn.cursor()
        cursor.execute(
            "SELECT id FROM monitoring WHERE branch=? AND ip=?", (branch, ip)
        )
        if cursor.fetchone():
            cursor.execute(
                "UPDATE monitoring SET name=?, type=? WHERE branch=? AND ip=?",
                (name, type_, branch, ip),
            )
        else:
            cursor.execute(
                "INSERT INTO monitoring (branch, name, type, ip) VALUES (?, ?, ?, ?)",
                (branch, name, type_, ip),
            )
        self.conn.commit()

    def delete_monitoring(self, branch, name, ip):
        cursor = self.conn.cursor()
        cursor.execute(
            "DELETE FROM monitoring WHERE branch=? AND name=? AND ip=?",
            (branch, name, ip),
        )
        self.conn.commit()

    def get_monitoring_data(self):
        # تبدیل داده‌های فلت دیتابیس به ساختار درختی برای QML
        cursor = self.conn.cursor()
        cursor.execute("SELECT branch, name, type, ip FROM monitoring")
        rows = cursor.fetchall()
        data_map = {}
        for row in rows:
            branch, name, type_, ip = row
            if branch not in data_map:
                data_map[branch] = []
            data_map[branch].append(
                {
                    "sysName": name,
                    "sysType": type_,
                    "sysIp": ip,
                    "statusColor": "#3b4252",
                }
            )
        result = []
        for branch, systems in data_map.items():
            priority = {"Router": 0, "Server": 1, "NVR": 2, "Checkout": 3, "Client": 4}
            systems.sort(key=lambda x: priority.get(x["sysType"], 5))
            result.append({"branchName": branch, "systems": systems})
        return json.dumps(result)

    def get_flat_monitoring_list(self):
        cursor = self.conn.cursor()
        cursor.execute("SELECT branch, name, ip FROM monitoring")
        return cursor.fetchall()

    def add_destination(self, district, branch, name, ip):
        cursor = self.conn.cursor()
        cursor.execute(
            "INSERT INTO destinations (district, branch, name, ip) VALUES (?, ?, ?, ?)",
            (district, branch, name, ip),
        )
        self.conn.commit()

    def delete_destination(self, district, branch, name, ip):
        cursor = self.conn.cursor()
        cursor.execute(
            "DELETE FROM destinations WHERE district=? AND branch=? AND name=? AND ip=?",
            (district, branch, name, ip),
        )
        self.conn.commit()

    def get_destination_data(self):
        # تبدیل داده‌های مقصد به ساختار درختی (منطقه -> شعبه -> سیستم)
        cursor = self.conn.cursor()
        cursor.execute("SELECT district, branch, name, ip FROM destinations")
        rows = cursor.fetchall()
        dist_map = {}
        for row in rows:
            dist, branch, name, ip = row
            if dist not in dist_map:
                dist_map[dist] = {}
            if branch not in dist_map[dist]:
                dist_map[dist][branch] = []
            dist_map[dist][branch].append(
                {"sysName": name, "sysType": "Client", "sysIp": ip, "checked": False}
            )
        result = []
        for dist_name, branches in dist_map.items():
            branch_list = []
            for branch_name, systems in branches.items():
                branch_list.append(
                    {"branchName": branch_name, "checked": False, "systems": systems}
                )
            result.append(
                {"districtName": dist_name, "checked": False, "branches": branch_list}
            )
        return json.dumps(result)
