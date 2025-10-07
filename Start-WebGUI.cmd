@echo off
title TL1 Assistant - Web GUI
echo.
echo ========================================
echo    TL1 Assistant - Web GUI Launcher
echo ========================================
echo.

REM Check if Python is available
python --version >nul 2>&1
if errorlevel 1 (
    echo ❌ Python not found. Please install Python 3.7+ first.
    echo.
    echo Download from: https://www.python.org/downloads/
    pause
    exit /b 1
)

echo ✅ Python found
echo 🚀 Starting TL1 Assistant Web GUI...
echo.

REM Run the web GUI
python tl1_web_gui.py

echo.
echo Press any key to exit...
pause >nul