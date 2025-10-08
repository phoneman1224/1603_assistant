@echo off
title TL1 Assistant - One-Click Installer and Launcher

echo ====================================================
echo          TL1 Assistant - One-Click Start
echo ====================================================
echo.
echo This will install all dependencies and start the application.
echo.
echo NOTE: If Node.js is not installed, the desktop GUI will launch.
echo For the modern web interface, install Node.js from nodejs.org
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
echo [SUCCESS] TL1 Assistant is now running!
echo.
echo To get the modern web interface:
echo 1. Install Node.js from https://nodejs.org/
echo 2. Run this script again
echo.
pause