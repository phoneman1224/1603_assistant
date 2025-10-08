@echo off
REM TL1 Assistant - Simple Startup Script
REM This script starts the TL1 Assistant with minimal setup

echo ==========================================
echo     TL1 Assistant - Network Manager
echo ==========================================
echo.

REM Check if we're in the right directory
if not exist "requirements.txt" (
    echo ❌ Error: Please run this script from the TL1 Assistant directory
    pause
    exit /b 1
)

REM Check Python
python --version >nul 2>&1
if errorlevel 1 (
    echo ❌ Error: Python 3 is required but not installed
    echo Please install Python from https://python.org
    pause
    exit /b 1
)

echo 🔧 Setting up Python environment...

REM Create virtual environment if it doesn't exist
if not exist ".venv" (
    python -m venv .venv
)

REM Activate virtual environment
call .venv\Scripts\activate.bat

REM Install requirements
echo 📦 Installing Python dependencies...
pip install -q -r requirements.txt

REM Check if Node.js is available for web interface
node --version >nul 2>&1
if errorlevel 1 goto :api_only

npm --version >nul 2>&1
if errorlevel 1 goto :api_only

echo 🌐 Setting up web interface...
cd webui
if not exist "node_modules" (
    npm install -q
)

REM Build the frontend
npm run build -q
cd ..

echo.
echo ✅ Starting TL1 Assistant with Web Interface...
echo.
echo 🌐 Web Interface: http://localhost:8000
echo 📡 API Endpoints: http://localhost:8000/docs
echo.
echo Press Ctrl+C to stop
echo.

REM Start the backend (which serves the frontend)
python main.py
goto :end

:api_only
echo.
echo ⚠️  Node.js not found - starting API-only mode
echo.
echo 📡 API Server: http://localhost:8000
echo 📖 API Documentation: http://localhost:8000/docs
echo.
echo To get the full web interface, install Node.js from https://nodejs.org
echo.
echo Press Ctrl+C to stop
echo.

REM Start the backend only
python main.py

:end