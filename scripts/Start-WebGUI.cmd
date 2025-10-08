@echo off
title TL1 Assistant - Web GUI
echo.
echo ========================================
echo    TL1 Assistant - Web GUI Launcher
echo ========================================
echo.

REM Try different Python commands in order of preference
set "PYTHON_CMD="

REM Try py launcher first (Windows recommended)
py --version >nul 2>&1
if not errorlevel 1 (
    set "PYTHON_CMD=py"
    goto :found_python
)

REM Try python3
python3 --version >nul 2>&1
if not errorlevel 1 (
    set "PYTHON_CMD=python3"
    goto :found_python
)

REM Try python
python --version >nul 2>&1
if not errorlevel 1 (
    set "PYTHON_CMD=python"
    goto :found_python
)

REM No Python found
echo ❌ Python not found. Please install Python 3.6+ first.
echo.
echo Download from: https://www.python.org/downloads/
echo Make sure to check "Add Python to PATH" during installation
pause
exit /b 1

:found_python
echo ✅ Python found (%PYTHON_CMD%)
echo 🚀 Starting TL1 Assistant Web GUI...
echo.

REM Change to script directory
cd /d "%~dp0"

REM Run the web GUI
%PYTHON_CMD% tl1_web_gui.py

echo.
echo Press any key to exit...
pause >nul