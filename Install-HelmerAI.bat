@echo off
setlocal EnableExtensions
rem Helmer AI one-click install. UAC Yes only. No irm/iex. No GitHub login.
rem Double-click this file from the unzipped folder (same folder as Install-HelmerAI.ps1).

net session >nul 2>&1
if %errorlevel% neq 0 (
  powershell.exe -NoProfile -ExecutionPolicy Bypass -Command "try { $p = Start-Process -FilePath '%~f0' -Verb RunAs -Wait -PassThru; exit $p.ExitCode } catch { Write-Host 'Administrator approval was canceled.'; exit 1 }"
  exit /b %errorlevel%
)

cd /d "%~dp0"
if not exist "%~dp0Install-HelmerAI.ps1" (
  echo ERROR: Install-HelmerAI.ps1 not found next to this .bat
  echo Unzip the full HelmerAI-Install.zip and run Install-HelmerAI.bat from that folder.
  pause
  exit /b 1
)

rem Interactive: node name and role come from this PC; RustDesk password, Tailscale and auto-login prompts run.
echo Running Install-HelmerAI.ps1 ...
powershell.exe -NoProfile -ExecutionPolicy Bypass -File "%~dp0Install-HelmerAI.ps1"
set ERR=%ERRORLEVEL%
echo.
echo Exit code: %ERR%
echo Log: C:\HelmerAI\install.log
if %ERR% neq 0 pause
exit /b %ERR%
