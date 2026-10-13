# Helmer AI bootstrap (public, secret-free)

One UAC Yes. No GitHub sign-in.

## Install (Admin PowerShell)

Open PowerShell as administrator and paste:

```powershell
$f="$env:TEMP\Get-HelmerAI.ps1"; irm https://github.com/jehelmer-oss/helmerai-bootstrap/releases/latest/download/Get-HelmerAI.ps1 -OutFile $f; powershell -ExecutionPolicy Bypass -File $f
```

This downloads the latest release `Get-HelmerAI.ps1` and runs it with `-File` (not `irm | iex`).

## Double-click alternative

1. Download `HelmerAI-Install.zip` from [Releases](https://github.com/jehelmer-oss/helmerai-bootstrap/releases/latest)
2. Unzip the whole folder
3. Double-click `Install-HelmerAI.bat`
4. Click Yes on UAC

The bat runs `Install-HelmerAI.ps1` interactively from the same folder via `powershell -File` (node name and role come from the PC; RustDesk password, Tailscale sign-in and auto-login prompts run). Set `HELMERAI_UNATTENDED=1` before the one-liner to skip prompts.

No API keys or passwords in this repo or the release zip.
