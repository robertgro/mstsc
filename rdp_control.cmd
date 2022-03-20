@echo off
::DEBUG
powershell -ExecutionPolicy Unrestricted -File rdp_control.ps1
::PROD
::powershell -ExecutionPolicy Unrestricted -File rdp_control.ps1
pause