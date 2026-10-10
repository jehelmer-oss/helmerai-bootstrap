# Helmer AI bootstrap (secret-free). Justin Surface / any Windows PC.
# One-liner (Admin PowerShell):
#   irm https://raw.githubusercontent.com/jehelmer-oss/helmerai-bootstrap/main/Get-HelmerAI.ps1 | iex
# Optional env before running:
#   $env:HELMERAI_ROLE = 'field'          # worker|field (default field on this bootstrap)
#   $env:HELMERAI_NODE  = 'surface'       # node name
#   $env:HELMERAI_DRYRUN = '1'            # dry-run only
#No secrets. Pulls private jehelmer-oss/mac-feed via YOUR GitHub login, then runs Install-HelmerAI.ps1.
$ErrorActionPreference = 'Stop'
$ProgressPreference = 'SilentlyContinue'
$Role = if ($env:HELMERAI_ROLE) { $env:HELMERAI_ROLE } else { 'field' }
$Node = if ($env:HELMERAI_NODE) { $env:HELMERAI_NODE } else { 'surface' }
$Dry = [bool]($env:HELMERAI_DRYRUN -eq '1')
$Repo = 'jehelmer-oss/mac-feed'
$Root = if ($env:HELMERAI_ROOT) { $env:HELMERAI_ROOT } else { 'C:\HelmerAI' }

# Self-elevate
$id = [Security.Principal.WindowsIdentity]::GetCurrent()
$p = New-Object Security.Principal.WindowsPrincipal($id)
if (-not $p.IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)) {
    $arg = "-NoProfile -ExecutionPolicy Bypass -Command `"irm 'https://raw.githubusercontent.com/jehelmer-oss/helmerai-bootstrap/main/Get-HelmerAI.ps1' | iex`""
    Start-Process -Verb RunAs -FilePath powershell.exe -ArgumentList $arg | Out-Null
    return
}

function Ensure-WingetId([string]$Id, [string]$Label) {
    $have = winget list -e --id $Id --accept-source-agreements 2>$null | Out-String
    if ($have -notmatch [regex]::Escape($Id)) {
        Write-Host "Installing $Label..." -ForegroundColor Yellow
        winget install -e --id $Id --silent --accept-package-agreements --accept-source-agreements --disable-interactivity | Out-Null
    }
}
Write-Host "Helmer AI bootstrap -> role=$Role node=$Node dry=$Dry" -ForegroundColor Cyan
Ensure-WingetId 'Git.Git' 'Git'
Ensure-WingetId 'GitHub.cli' 'GitHub CLI'
$env:Path = [Environment]::GetEnvironmentVariable('Path','Machine') + ';' + [Environment]::GetEnvironmentVariable('Path','User')
$gh = @(
    "$env:ProgramFiles\GitHub CLI\gh.exe",
    (Get-Command gh -ErrorAction SilentlyContinue | Select-Object -ExpandProperty Source -First 1)
) | Where-Object { $_ -and (Test-Path $_) } | Select-Object -First 1
if (-not $gh) { throw 'gh not found after winget install' }

& $gh auth status -h github.com 2>$null
if ($LASTEXITCODE -ne 0) {
    Write-Host 'Sign in to GitHub (need access to jehelmer-oss/mac-feed)...' -ForegroundColor Yellow
    & $gh auth login -h github.com -p https -w | Out-Host
}
& $gh auth status -h github.com | Out-Host

$Src = Join-Path $Root 'src\mac-feed'
New-Item -ItemType Directory -Path (Split-Path $Src) -Force | Out-Null
if (Test-Path (Join-Path $Src '.git')) {
    Write-Host "Pulling $Repo ..." -ForegroundColor Cyan
    & $gh -C $Src repo sync 2>$null
    if ($LASTEXITCODE -ne 0) { git -C $Src pull --ff-only }
} else {
    if (Test-Path $Src) { Remove-Item $Src -Recurse -Force }
    Write-Host "Cloning $Repo ..." -ForegroundColor Cyan
    & $gh repo clone $Repo $Src -- --depth 1
    if ($LASTEXITCODE -ne 0) { throw "clone failed: $Repo" }
}

$Installer = Join-Path $Src 'windows\Install-HelmerAI.ps1'
if (-not (Test-Path $Installer)) { throw "missing $Installer" }
$psArgs = @('-NoProfile','-ExecutionPolicy','Bypass','-File',$Installer,'-Role',$Role,'-NodeName',$Node,'-GitHub')
if ($Dry) { $psArgs += '-DryRun' }
Write-Host "Running Install-HelmerAI.ps1 $($psArgs -join ' ')" -ForegroundColor Cyan
& powershell.exe @psArgs
$code = $LASTEXITCODE
Write-Host "Install exit $code. Log: $Root\install.log" -ForegroundColor $(if ($code -eq 0) { 'Green' } else { 'Yellow' })
if ($code -ne 0) { exit $code }
