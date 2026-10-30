@echo off
cd /d "%~dp0"
echo stop> stop.flag
rem ask the bot to disconnect cleanly first (up to 10 s), then force-stop if it is still running
if exist data echo stop> data\stop.request
for /l %%i in (1,1,20) do (
  tasklist /FI "IMAGENAME eq TS3AudioBot.exe" 2>nul | find /i "TS3AudioBot.exe" >nul || goto :done
  ping -n 2 127.0.0.1 >nul
)
:done
del data\stop.request >nul 2>&1
taskkill /F /IM TS3AudioBot.exe >nul 2>&1
echo Bot stopped.
