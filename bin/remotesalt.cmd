@echo off
rem Helper: %1 = salt binary name, rest = args. Single-quotes each arg so the
rem remote bash inside the container doesn't glob-expand targets like *.
rem Injects --force-color for every salt CLI: output is piped through ssh +
rem docker exec (no TTY), so salt drops color unless forced.
setlocal enabledelayedexpansion
set "bin=%~1"
shift
set "args="
:loop
if "%~1"=="" goto run
set "args=!args! '%~1'"
shift
goto loop
:run
ssh ubuntu@51.178.66.98 "docker exec salt-master %bin% --force-color!args!"
endlocal
