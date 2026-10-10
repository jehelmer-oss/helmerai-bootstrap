# Helmer AI bootstrap (public, secret-free, unattended)

One UAC Yes. No GitHub sign-in. No other prompts.

## Double-click

Download `HelmerAI-Install.zip` from [Releases](https://github.com/jehelmer-oss/helmerai-bootstrap/releases/latest), unzip, double-click `Install-HelmerAI.bat`.

## One-liner

Admin PowerShell:

```powershell
irm https://raw.githubusercontent.com/jehelmer-oss/helmerai-bootstrap/main/Get-HelmerAI.ps1 | iex
```

Downloads `helmerai-windows.zip` from this repo’s latest release (public), extracts, runs `Install-HelmerAI.ps1 -Unattended`.

Defaults: `role=field`, `node=surface`. Override with `$env:HELMERAI_ROLE` / `$env:HELMERAI_NODE`.

No API keys, tokens, or passwords in this repo or the release zip.
Ongoing node updates use the public release manifest (or a read-only deploy key provisioned later over Tailscale — never embedded here).
