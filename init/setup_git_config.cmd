@echo off
echo Setting up Git configurations...
git config --global pull.rebase false
git config --global push.default current
git config --global core.autocrlf true
git config --global safe.directory *
git config --global credential.helper store

echo Configuration complete!
echo.
echo Your Git is now configured to:
echo - Automatically accept pulls
echo - Use simple push behavior
echo - Handle line endings
echo - Store credentials
echo.
pause