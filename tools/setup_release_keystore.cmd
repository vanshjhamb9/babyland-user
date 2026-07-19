@echo off
cd /d "%~dp0.."
echo Running release keystore setup...
echo.
powershell -NoProfile -ExecutionPolicy Bypass -File "%~dp0setup_release_keystore.ps1"
echo.
pause
