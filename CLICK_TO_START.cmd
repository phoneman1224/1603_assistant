@echo off
title TL1 Assistant - One-Click Installer and Launcher

echo ====================================================
echo          TL1 Assistant - One-Click Start
echo ====================================================
echo.
echo This will install all dependencies and start the application.
echo.
echo Press any key to continue, or close this window to cancel...
pause >nul

echo.
echo [INFO] Setting working directory to script location...

REM Change to the directory where this script is located
cd /d "%~dp0"

echo [INFO] Working directory: %CD%
echo [INFO] Starting PowerShell bootstrap script...
echo.

powershell -NoProfile -ExecutionPolicy Bypass -File "%~dp0START_HERE.ps1"

if %ERRORLEVEL% NEQ 0 (
    echo.
    echo [ERROR] Installation failed. Please check the output above.
    echo.
    pause
    exit /b 1
)

echo.
echo Installation and launch complete!
pause