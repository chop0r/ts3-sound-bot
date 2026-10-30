@echo off
cd /d "%~dp0"
start "" /min powershell.exe -NoProfile -WindowStyle Hidden -ExecutionPolicy Bypass -File "%~dp0run-bot.ps1"
echo Bot started in the background. Stop it with stop.cmd
