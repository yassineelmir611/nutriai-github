@echo off
setlocal
powershell -ExecutionPolicy Bypass -File "%~dp0connect_phone.ps1" %*
endlocal
