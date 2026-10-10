# Helmer AI bootstrap (public, secret-free)

Drive flags `.ps1` / `.cmd` / installer zips as abuse. Use this instead.

## Windows (Surface)

Admin PowerShell:

```powershell
irm https://raw.githubusercontent.com/jehelmer-oss/helmerai-bootstrap/main/Get-HelmerAI.ps1 | iex
```

Defaults: `-Role field -NodeName surface`. Set `$env:HELMERAI_ROLE` / `$env:HELMERAI_NODE` before the one-liner to override.

Pulls private `jehelmer-oss/mac-feed` via your GitHub login, then runs `windows/Install-HelmerAI.ps1`.

No API keys, tokens, or passwords in this repo.
