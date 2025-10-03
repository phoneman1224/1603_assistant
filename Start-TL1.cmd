@echo off
setlocal
REM Start-TL1.cmd — Windows launcher
cd /d "%~dp0"
where py >nul 2>nul || where python >nul 2>nul
if %ERRORLEVEL% NEQ 0 (
  echo [INFO] Python not found. Attempting winget install...
  where winget >nul 2>nul && (
    winget install -e --id Python.Python.3 --accept-package-agreements --accept-source-agreements
  ) || (
    echo [WARN] winget not available. You can install Python later if needed.
  )
)
set PS1="powershell\TL1_CommandBuilder.ps1"
if not exist %PS1% (
  echo [ERROR] %PS1% not found. Pull the full repo.
  pause
  exit /b 1
)
powershell -NoLogo -NoProfile -ExecutionPolicy Bypass -File "%PS1%"
endlocal
