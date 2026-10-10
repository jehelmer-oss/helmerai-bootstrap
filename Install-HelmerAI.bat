@echo off
rem Helmer AI — one-click install (UAC Yes only; no GitHub sign-in).
rem Double-click this file. Safe to re-run.
net session >nul 2>&1
if %errorlevel% neq 0 (
  powershell -NoProfile -Command "Start-Process -Verb RunAs -FilePath '%~f0'"
  exit /b
)
powershell -NoProfile -ExecutionPolicy Bypass -Command "irm https://raw.githubusercontent.com/jehelmer-oss/helmerai-bootstrap/main/Get-HelmerAI.ps1 | iex"
echo.
echo Log: C:\HelmerAI\install.log
pause
