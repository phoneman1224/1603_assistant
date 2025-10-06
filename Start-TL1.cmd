@echo off
setlocal
REM Start-TL1.cmd — Windows launcher (WPF needs STA)
cd /d "%~dp0"

REM Optional: Python check via winget (won't block GUI)
where py >nul 2>nul || where python >nul 2>nul
if %ERRORLEVEL% NEQ 0 (
  where winget >nul 2>nul && (
    echo [INFO] Python not found. Installing via winget (optional)...
    winget install -e --id Python.Python.3 --accept-package-agreements --accept-source-agreements
  ) || (
    echo [WARN] winget not available; skipping optional Python install.
  )
)

set PS1="powershell\TL1_CommandBuilder.ps1"
if not exist %PS1% (
  echo [ERROR] %PS1% not found. Make sure the repo is fully pulled.
  pause
  exit /b 1
)

REM Force STA or WPF will crash/close immediately
powershell -NoLogo -NoProfile -ExecutionPolicy Bypass -Sta -File "%PS1%"
if %ERRORLEVEL% NEQ 0 (
  echo [ERROR] PowerShell exited with code %ERRORLEVEL%.
  echo Try running from a console to see details:
  echo   powershell -NoLogo -NoProfile -ExecutionPolicy Bypass -Sta -File powershell\TL1_CommandBuilder.ps1
  pause
)
endlocal
