# Helmer AI bootstrap (public, secret-free, unattended)

One UAC Yes. No GitHub sign-in.

## Install (Admin PowerShell)

Open PowerShell as administrator and paste:

```powershell
irm https://raw.githubusercontent.com/jehelmer-oss/helmerai-bootstrap/main/Get-HelmerAI.ps1 | iex
```

Works on Windows PowerShell 5.1. `Get-HelmerAI.ps1` is UTF-8 without a BOM and ASCII-only so `irm | iex` can parse the downloaded string.

Safer alternative (download, then `-File`):

```powershell
$f="$env:TEMP\Get-HelmerAI.ps1"; irm https://github.com/jehelmer-oss/helmerai-bootstrap/releases/latest/download/Get-HelmerAI.ps1 -OutFile $f; powershell -ExecutionPolicy Bypass -File $f
```

## Double-click alternative

1. Download `HelmerAI-Install.zip` from [Releases](https://github.com/jehelmer-oss/helmerai-bootstrap/releases/latest)
2. Unzip the whole folder
3. Double-click `Install-HelmerAI.bat`
4. Click Yes on UAC

The bat runs `Install-HelmerAI.ps1 -Unattended` from the same folder via `powershell -File`.

No API keys or passwords in this repo or the release zip.
