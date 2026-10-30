@echo off
cd /d "%~dp0"
echo stop> stop.flag
taskkill /F /IM TS3AudioBot.exe >nul 2>&1
echo Bot stopped.
