# -*- mode: python ; coding: utf-8 -*-

block_cipher = None

a = Analysis(
    ['main.py'],
    pathex=[],
    binaries=[],
    datas=[
        ('ui', 'ui'),  # کپی کردن پوشه ui به داخل فایل exe
        ('backend', 'backend') # کپی کردن کدهای بک‌اند
    ],
    hiddenimports=[
        'PyQt6.QtQuick',
        'PyQt6.QtQml',
        'PyQt6.QtNetwork', # مانیتورینگ به این نیاز دارد
        'PyQt6.QtCore',
        'PyQt6.QtGui'
    ],
    hookspath=[],
    hooksconfig={},
    runtime_hooks=[],
    excludes=[
        'tkinter', 'unittest', 'email', 'http', 'xml', 'pydoc', 
        'pdb', 'distutils', 'setuptools', 'asyncio'
    ],  # حذف ماژول‌های غیرضروری برای کاهش حجم
    win_no_prefer_redirects=False,
    win_private_assemblies=False,
    cipher=block_cipher,
    noarchive=False,
)

pyz = PYZ(a.pure, a.zipped_data, cipher=block_cipher)

exe = EXE(
    pyz,
    a.scripts,
    a.binaries,
    a.zipfiles,
    a.datas,
    [],
    name='NetworkDashboard',  # نام فایل خروجی
    debug=False,
    bootloader_ignore_signals=False,
    strip=False,
    upx=True,        # فشرده‌سازی با UPX (اگر نصب باشد)
    upx_exclude=[],
    runtime_tmpdir=None,
    console=False,   # عدم نمایش صفحه سیاه CMD
    disable_windowed_traceback=False,
    argv_emulation=False,
    target_arch=None,
    codesign_identity=None,
    entitlements_file=None,
    icon='icon.ico', # اگر آیکون دارید این خط را از کامنت درآورید
)