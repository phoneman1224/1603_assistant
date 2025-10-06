@echo off
setlocal
REM Start-TL1.cmd — Windows launcher for WPF (STA required)
cd /d "%~dp0"

set "PS1=%~dp0powershell\TL1_CommandBuilder.ps1"
if not exist "%PS1%" (
  echo [ERROR] %PS1% not found. Make sure the repo is fully pulled.
  pause
  exit /b 1
)

powershell -NoLogo -NoProfile -ExecutionPolicy Bypass -Sta -File "%PS1%"
if %ERRORLEVEL% NEQ 0 (
  echo [ERROR] PowerShell exited with code %ERRORLEVEL%.
  echo Try running from a console to see details:
  echo   powershell -NoLogo -NoProfile -ExecutionPolicy Bypass -Sta -File "powershell\TL1_CommandBuilder.ps1"
  pause
)
endlocal
