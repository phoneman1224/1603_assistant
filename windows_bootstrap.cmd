@echo off
setlocal
set PS1=%~dp0windows_bootstrap.ps1
powershell -NoProfile -ExecutionPolicy Bypass -File "%PS1%"
endlocal
