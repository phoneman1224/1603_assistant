@echo off
echo.
echo ============================================
echo          TL1 Assistant Launcher
echo ============================================
echo.

REM Check if PowerShell is available
powershell -Command "Write-Host 'PowerShell is available'" >nul 2>&1
if %errorlevel% neq 0 (
    echo ERROR: PowerShell is not available on this system
    echo Please ensure PowerShell is installed
    pause
    exit /b 1
)

REM Get the directory where this batch file is located
set "SCRIPT_DIR=%~dp0"
set "LAUNCHER_SCRIPT=%SCRIPT_DIR%Launch-TL1Assistant.ps1"

echo Script Directory: %SCRIPT_DIR%
echo Launcher Script: %LAUNCHER_SCRIPT%
echo.

REM Check if launcher script exists
if not exist "%LAUNCHER_SCRIPT%" (
    echo ERROR: Launch-TL1Assistant.ps1 not found!
    echo Expected location: %LAUNCHER_SCRIPT%
    echo.
    echo Please ensure all files are properly extracted from the repository
    pause
    exit /b 1
)

echo Launching TL1 Assistant...
echo.

REM Launch the PowerShell launcher with bypass execution policy
powershell.exe -ExecutionPolicy Bypass -File "%LAUNCHER_SCRIPT%"

echo.
echo TL1 Assistant has closed.
pause