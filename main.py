import sys
import os
import ctypes
from PyQt6.QtWidgets import QApplication
from PyQt6.QtQml import QQmlApplicationEngine
from PyQt6.QtCore import QUrl

# Import Backend logic and Utils
from backend.bridge import Backend
from backend.utils import generate_network_icon

os.environ["QT_QUICK_CONTROLS_STYLE"] = "Basic"


if __name__ == "__main__":
    # Fix Windows Taskbar Icon Grouping
    if os.name == "nt":
        myappid = "company.netmanager.dashboard.v1"
        try:
            ctypes.windll.shell32.SetCurrentProcessExplicitAppUserModelID(myappid)
        except:
            pass

    app = QApplication(sys.argv)
    app.setWindowIcon(generate_network_icon())

    engine = QQmlApplicationEngine()
    backend = Backend()
    engine.rootContext().setContextProperty("backend", backend)

    # --- PATH LOGIC FOR PYINSTALLER & DEV MODE ---
    if getattr(sys, "frozen", False):
        # Exe Mode: Temporary folder
        base_path = sys._MEIPASS
    else:
        # Dev Mode: Current folder
        base_path = os.path.dirname(os.path.abspath(__file__))

    # Pointing to the new location of main.qml inside 'ui' folder
    qml_file_path = os.path.join(base_path, "ui", "main.qml")
    engine.load(QUrl.fromLocalFile(qml_file_path))
    # -----------------------------------------------

    if not engine.rootObjects():
        sys.exit(-1)
    sys.exit(app.exec())
