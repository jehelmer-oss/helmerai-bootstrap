# Helmer AI bootstrap (public, secret-free, unattended)

One UAC Yes. No GitHub sign-in. No irm|iex in the double-click path.

## Double-click (recommended)

1. Download `HelmerAI-Install.zip` from [Releases](https://github.com/jehelmer-oss/helmerai-bootstrap/releases/latest)
2. Unzip the whole folder
3. Double-click `Install-HelmerAI.bat`
4. Click Yes on UAC

The bat runs `Install-HelmerAI.ps1 -Unattended` from the same folder via `powershell -File`.

## Optional one-liner (Admin PowerShell)

Still available for advanced use (downloads the release zip, then runs -File):

```powershell
irm https://raw.githubusercontent.com/jehelmer-oss/helmerai-bootstrap/main/Get-HelmerAI.ps1 | iex
```

No API keys or passwords in this repo or the release zip.
