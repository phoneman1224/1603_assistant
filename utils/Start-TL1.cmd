@echo off
setlocal EnableDelayedExpansion
REM Start-TL1.cmd — Windows launcher for WPF (STA required)

echo [INFO] Starting TL1 Command Builder...
echo [INFO] Current directory: %CD%

cd /d "%~dp0"
echo [INFO] Changed to script directory: %CD%

set "PS1=%~dp0powershell\TL1_CommandBuilder.ps1"
echo [INFO] PowerShell script path: %PS1%
if not exist "%PS1%" (
    echo [ERROR] %PS1% not found. Make sure the repo is fully pulled.
    pause
    exit /b 1
)

REM Create a debug log file
set "DEBUG_LOG=%~dp0debug.log"
echo [%DATE% %TIME%] Debug Log Started > "%DEBUG_LOG%"
echo Current Directory: %CD% >> "%DEBUG_LOG%"

REM Check for PowerShell version and launch appropriately
echo [INFO] Checking PowerShell version...
powershell -NoProfile -Command "$PSVersionTable.PSVersion.Major" > "%TEMP%\psver.txt" 2>> "%DEBUG_LOG%"
set /p PSVER=<"%TEMP%\psver.txt"
del "%TEMP%\psver.txt"
echo [INFO] PowerShell version detected: %PSVER% >> "%DEBUG_LOG%"

if %PSVER% GTR 5 (
    echo [ERROR] This application requires Windows PowerShell 5.1
    echo Current version detected: PowerShell %PSVER%
    echo Please run using "Windows PowerShell" ^(blue icon^) instead of "PowerShell" ^(black icon^)
    echo.
    echo Press any key to open with Windows PowerShell...
    pause >nul
    echo [INFO] Launching with Windows PowerShell 5.1...
    start /b /wait powershell.exe -NoLogo -NoProfile -ExecutionPolicy Bypass -Sta -File "%PS1%" 2>> "%DEBUG_LOG%"
) else (
    echo [INFO] Launching with detected PowerShell...
    powershell -NoLogo -NoProfile -ExecutionPolicy Bypass -Sta -File "%PS1%" 2>> "%DEBUG_LOG%"
)

set PS_ERROR=%ERRORLEVEL%
echo [INFO] PowerShell exit code: %PS_ERROR% >> "%DEBUG_LOG%"

if %PS_ERROR% NEQ 0 (
    echo [ERROR] PowerShell exited with code %PS_ERROR%.
    echo [ERROR] Please check debug.log for details
    echo [ERROR] Try running from a console using this command:
    echo   powershell -NoLogo -NoProfile -ExecutionPolicy Bypass -Sta -File "powershell\TL1_CommandBuilder.ps1"
    echo.
    echo Press any key to exit...
    pause >nul
)

echo [INFO] Debug log saved to: %DEBUG_LOG%
echo.
echo If the application didn't start correctly, please check debug.log
echo Press any key to exit...
pause >nul
endlocal
