@echo off
setlocal EnableExtensions
rem Helmer AI one-click install. UAC Yes only. No irm/iex. No GitHub login.
rem Double-click this file from the unzipped folder (same folder as Install-HelmerAI.ps1).

net session >nul 2>&1
if %errorlevel% neq 0 (
  powershell.exe -NoProfile -ExecutionPolicy Bypass -Command "Start-Process -FilePath '%~f0' -Verb RunAs"
  exit /b
)

cd /d "%~dp0"
if not exist "%~dp0Install-HelmerAI.ps1" (
  echo ERROR: Install-HelmerAI.ps1 not found next to this .bat
  echo Unzip the full HelmerAI-Install.zip and run Install-HelmerAI.bat from that folder.
  pause
  exit /b 1
)

echo Running Install-HelmerAI.ps1 -Unattended ...
powershell.exe -NoProfile -ExecutionPolicy Bypass -File "%~dp0Install-HelmerAI.ps1" -Role field -NodeName surface -Unattended
set ERR=%ERRORLEVEL%
echo.
echo Exit code: %ERR%
echo Log: C:\HelmerAI\install.log
if %ERR% neq 0 pause
exit /b %ERR%
