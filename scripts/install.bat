@echo off
REM TL1 Assistant Installation Script for Windows
REM Version 1.0.0

setlocal enabledelayedexpansion

echo ======================================
echo    TL1 Assistant Installation Script
echo ======================================
echo.

REM Installation configuration
set "INSTALL_DIR=%USERPROFILE%\TL1Assistant"
set "APP_NAME=TL1 Assistant"
set "PYTHON_MIN_VERSION=3.6"

REM Check if Python is installed
echo [INFO] Checking Python installation...
python --version >nul 2>&1
if !errorlevel! neq 0 (
    py --version >nul 2>&1
    if !errorlevel! neq 0 (
        echo [ERROR] Python is not installed or not found in PATH
        echo Please install Python 3.6 or higher from https://python.org
        echo Make sure to check "Add Python to PATH" during installation
        pause
        exit /b 1
    ) else (
        set "PYTHON_CMD=py"
    )
) else (
    set "PYTHON_CMD=python"
)

REM Get Python version
for /f "tokens=2" %%i in ('!PYTHON_CMD! --version 2^>^&1') do set "PYTHON_VERSION=%%i"
echo [INFO] Found Python version: !PYTHON_VERSION!

REM Check if pip is available
echo [INFO] Checking pip installation...
!PYTHON_CMD! -m pip --version >nul 2>&1
if !errorlevel! neq 0 (
    echo [ERROR] pip is not available
    echo Please ensure pip is installed with your Python installation
    pause
    exit /b 1
)

REM Create installation directory
echo [INFO] Creating installation directory...
if exist "!INSTALL_DIR!" (
    echo [WARNING] Installation directory already exists: !INSTALL_DIR!
    set /p "REPLY=Do you want to overwrite it? (y/N): "
    if /i not "!REPLY!"=="y" (
        echo Installation cancelled
        pause
        exit /b 1
    )
    rmdir /s /q "!INSTALL_DIR!"
)

mkdir "!INSTALL_DIR!"
mkdir "!INSTALL_DIR!\data"

REM Copy application files
echo [INFO] Installing TL1 Assistant files...
copy tl1_web_gui.py "!INSTALL_DIR!\" >nul
copy data\commands.json "!INSTALL_DIR!\data\" >nul
copy requirements.txt "!INSTALL_DIR!\" >nul
copy Start-WebGUI.cmd "!INSTALL_DIR!\" >nul

REM Copy documentation
echo [INFO] Installing documentation...
copy README.md "!INSTALL_DIR!\" >nul
copy quick_start.md "!INSTALL_DIR!\" >nul
copy tl1_syntax.md "!INSTALL_DIR!\" >nul
copy command_examples.json "!INSTALL_DIR!\" >nul
copy tap-001.md "!INSTALL_DIR!\" >nul
copy directory_structure.md "!INSTALL_DIR!\" >nul
copy version.json "!INSTALL_DIR!\" >nul

REM Install Python dependencies
echo [INFO] Installing Python dependencies...
cd /d "!INSTALL_DIR!"
!PYTHON_CMD! -m pip install -r requirements.txt --user

REM Create desktop shortcut
echo [INFO] Creating desktop shortcut...
set "SHORTCUT_PATH=%USERPROFILE%\Desktop\TL1 Assistant.lnk"
powershell -Command "& { ^
    $WshShell = New-Object -comObject WScript.Shell; ^
    $Shortcut = $WshShell.CreateShortcut('!SHORTCUT_PATH!'); ^
    $Shortcut.TargetPath = '!INSTALL_DIR!\Start-WebGUI.cmd'; ^
    $Shortcut.WorkingDirectory = '!INSTALL_DIR!'; ^
    $Shortcut.Description = 'TL1 Assistant - Web-based TL1 command interface'; ^
    $Shortcut.Save() ^
}"

REM Create Start Menu shortcut
echo [INFO] Creating Start Menu shortcut...
set "STARTMENU_PATH=%APPDATA%\Microsoft\Windows\Start Menu\Programs\TL1 Assistant.lnk"
powershell -Command "& { ^
    $WshShell = New-Object -comObject WScript.Shell; ^
    $Shortcut = $WshShell.CreateShortcut('!STARTMENU_PATH!'); ^
    $Shortcut.TargetPath = '!INSTALL_DIR!\Start-WebGUI.cmd'; ^
    $Shortcut.WorkingDirectory = '!INSTALL_DIR!'; ^
    $Shortcut.Description = 'TL1 Assistant - Web-based TL1 command interface'; ^
    $Shortcut.Save() ^
}"

REM Test installation
echo [INFO] Testing installation...
!PYTHON_CMD! -c "import sys; sys.path.insert(0, '.'); from tl1_web_gui import TL1Backend, load_commands_data; data = load_commands_data(); print(f'✅ Installation test passed - {len(data.get(\"commands\", {}))} commands loaded')"

if !errorlevel! equ 0 (
    echo.
    echo ======================================
    echo    Installation Completed Successfully
    echo ======================================
    echo.
    echo Installation location: !INSTALL_DIR!
    echo.
    echo To start TL1 Assistant:
    echo   Desktop shortcut: TL1 Assistant
    echo   Start Menu: TL1 Assistant
    echo   Manual start: !INSTALL_DIR!\Start-WebGUI.cmd
    echo.
    echo The web interface will open at: http://localhost:8080
    echo.
    echo Documentation available in: !INSTALL_DIR!
    echo   • README.md - Project overview
    echo   • quick_start.md - Getting started guide
    echo   • tap-001.md - Troubleshooting procedures
    echo.
    echo Installation complete! 🚀
    echo.
    
    set /p "REPLY=Would you like to start TL1 Assistant now? (y/N): "
    if /i "!REPLY!"=="y" (
        echo [INFO] Starting TL1 Assistant...
        start "" "!INSTALL_DIR!\Start-WebGUI.cmd"
    )
) else (
    echo [ERROR] Installation test failed
    echo Please check the error messages above and try again
    pause
    exit /b 1
)

pause