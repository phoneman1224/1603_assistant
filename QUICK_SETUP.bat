@echo off
REM Simple Windows batch script to bootstrap TL1 Assistant with Node.js auto-install

echo ================================================
echo TL1 Assistant - Windows Quick Start
echo ================================================
echo.

REM Check if we're in the right directory
if not exist "requirements.txt" (
    echo [ERROR] Please run this script from the root of the 1603_assistant repository
    pause
    exit /b 1
)

REM Step 1: Check Python
echo [1/4] Checking Python...
python --version >nul 2>&1
if %errorlevel% neq 0 (
    echo [ERROR] Python not found. Please install Python 3.8+ from python.org
    pause
    exit /b 1
)
echo [OK] Python found

REM Step 2: Install Python dependencies
echo.
echo [2/4] Installing Python dependencies...
pip install -r requirements.txt >nul 2>&1
if %errorlevel% neq 0 (
    echo [ERROR] Failed to install Python dependencies
    pause
    exit /b 1
)
echo [OK] Python dependencies installed

REM Step 3: Check Node.js and attempt auto-install
echo.
echo [3/4] Checking Node.js...
node --version >nul 2>&1
if %errorlevel% neq 0 (
    echo [WARNING] Node.js not found. Attempting to install...
    
    REM Try winget first
    winget --version >nul 2>&1
    if %errorlevel% equ 0 (
        echo [INFO] Installing Node.js via winget...
        winget install OpenJS.NodeJS --silent
        if %errorlevel% equ 0 (
            echo [OK] Node.js installed via winget
            goto :check_node_success
        )
    )
    
    REM Try chocolatey
    choco --version >nul 2>&1
    if %errorlevel% equ 0 (
        echo [INFO] Installing Node.js via chocolatey...
        choco install nodejs -y
        if %errorlevel% equ 0 (
            echo [OK] Node.js installed via chocolatey
            goto :check_node_success
        )
    )
    
    REM Manual installation fallback
    echo [INFO] Downloading Node.js installer...
    echo [INFO] Please install Node.js manually from: https://nodejs.org/
    echo [INFO] Download the Windows Installer (.msi) and run it
    echo [INFO] After installation, restart this script
    pause
    exit /b 1
    
    :check_node_success
    REM Refresh environment and check again
    echo [INFO] Refreshing environment...
    timeout /t 3 /nobreak >nul
    node --version >nul 2>&1
    if %errorlevel% equ 0 (
        echo [OK] Node.js is now available
    ) else (
        echo [WARNING] Node.js installed but may require terminal restart
    )
) else (
    echo [OK] Node.js found
)

REM Step 4: Install frontend dependencies if Node.js is available
echo.
echo [4/4] Setting up frontend...
node --version >nul 2>&1
if %errorlevel% equ 0 (
    if exist "webui\package.json" (
        echo [INFO] Installing frontend dependencies...
        cd webui
        npm install
        cd ..
        echo [OK] Frontend ready
    )
) else (
    echo [WARNING] Skipping frontend setup (Node.js not available)
)

echo.
echo ================================================
echo Setup complete! Choose how to start:
echo ================================================
echo.
echo 1. Desktop GUI (PowerShell): 
echo    powershell -File START_HERE.ps1 -LaunchDesktop
echo.
echo 2. Web GUI (Modern):
echo    powershell -File START_HERE.ps1
echo.
echo 3. Quick desktop start:
echo    powershell -File powershell\TL1_CommandBuilder.ps1
echo.

pause