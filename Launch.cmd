@echo off
"%SystemRoot%\System32\WindowsPowerShell\v1.0\powershell.exe" -NoLogo -NoProfile -File "%~dp0Start-AntigravityProxy.ps1"
if errorlevel 1 pause
