@echo off
rem Launcher: runs install-apps.ps1 without changing the system execution policy.
powershell.exe -NoProfile -ExecutionPolicy Bypass -File "%~dp0install-apps.ps1"
