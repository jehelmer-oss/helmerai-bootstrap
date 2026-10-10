# Helmer AI bootstrap (secret-free, no GitHub sign-in).
# One-liner (Admin PowerShell) OR double-click Install-HelmerAI.bat:
#   irm https://raw.githubusercontent.com/jehelmer-oss/helmerai-bootstrap/main/Get-HelmerAI.ps1 | iex
# Optional env before running:
#   $env:HELMERAI_ROLE = 'field'          # worker|field (default field)
#   $env:HELMERAI_NODE  = 'surface'       # node name
#   $env:HELMERAI_DRYRUN = '1'            # dry-run only
# Pulls the public release zip (no login). No secrets in this script.
$ErrorActionPreference = 'Stop'
$ProgressPreference = 'SilentlyContinue'
$Role = if ($env:HELMERAI_ROLE) { $env:HELMERAI_ROLE } else { 'field' }
$Node = if ($env:HELMERAI_NODE) { $env:HELMERAI_NODE } else { 'surface' }
$Dry = [bool]($env:HELMERAI_DRYRUN -eq '1')
$Root = if ($env:HELMERAI_ROOT) { $env:HELMERAI_ROOT } else { 'C:\HelmerAI' }
$PkgUrl = if ($env:HELMERAI_PKG_URL) { $env:HELMERAI_PKG_URL } else {
    'https://github.com/jehelmer-oss/helmerai-bootstrap/releases/latest/download/helmerai-windows.zip'
}
$BootstrapVer = '1.1.0'

function Update-HaiPath {
    $machine = [Environment]::GetEnvironmentVariable('Path', 'Machine')
    $user = [Environment]::GetEnvironmentVariable('Path', 'User')
    $env:Path = @($machine, $user | Where-Object { $_ }) -join ';'
}

function Invoke-NativeOk {
    param([scriptblock]$Cmd)
    $prev = $ErrorActionPreference
    try {
        $ErrorActionPreference = 'Continue'
        & $Cmd | Out-Null
        return ($LASTEXITCODE -eq 0)
    } catch {
        return $false
    } finally {
        $ErrorActionPreference = $prev
    }
}

# Self-elevate (only prompt: UAC Yes)
try {
    $id = [Security.Principal.WindowsIdentity]::GetCurrent()
    $prin = New-Object Security.Principal.WindowsPrincipal($id)
    $isAdmin = $prin.IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)
} catch {
    $isAdmin = $true  # non-Windows host / dry tooling
}
if (-not $isAdmin) {
    $arg = "-NoProfile -ExecutionPolicy Bypass -Command `"irm 'https://raw.githubusercontent.com/jehelmer-oss/helmerai-bootstrap/main/Get-HelmerAI.ps1' | iex`""
    Start-Process -Verb RunAs -FilePath powershell.exe -ArgumentList $arg | Out-Null
    return
}

Write-Host "Helmer AI bootstrap $BootstrapVer -> role=$Role node=$Node dry=$Dry (no GitHub login)" -ForegroundColor Cyan
New-Item -ItemType Directory -Path $Root -Force | Out-Null
$stage = Join-Path $env:TEMP ("helmerai-pkg-" + [guid]::NewGuid().ToString('n'))
$zip = Join-Path $env:TEMP 'helmerai-windows.zip'
New-Item -ItemType Directory -Path $stage -Force | Out-Null

Write-Host "Downloading package..." -ForegroundColor Cyan
try {
    Invoke-WebRequest -Uri $PkgUrl -OutFile $zip -UseBasicParsing
} catch {
    throw "download failed from $PkgUrl : $($_.Exception.Message)"
}
if (-not (Test-Path $zip) -or (Get-Item $zip).Length -lt 1000) { throw "package zip missing/too small: $zip" }

Write-Host "Extracting..." -ForegroundColor Cyan
Expand-Archive -LiteralPath $zip -DestinationPath $stage -Force
# Zip may contain a single top folder or flat windows files
$installer = Get-ChildItem -LiteralPath $stage -Recurse -Filter 'Install-HelmerAI.ps1' | Select-Object -First 1
if (-not $installer) { throw "Install-HelmerAI.ps1 not found inside package" }
$srcDir = $installer.DirectoryName
# Keep a local copy for the node updater (manifest + scripts) — no git clone needed
$local = Join-Path $Root 'src\windows-pkg'
if (Test-Path $local) { Remove-Item $local -Recurse -Force }
New-Item -ItemType Directory -Path (Split-Path $local) -Force | Out-Null
Copy-Item -LiteralPath $srcDir -Destination $local -Recurse -Force
$installerPath = Join-Path $local 'Install-HelmerAI.ps1'
if (-not (Test-Path $installerPath)) { $installerPath = (Get-ChildItem -LiteralPath $local -Recurse -Filter 'Install-HelmerAI.ps1' | Select-Object -First 1).FullName }

$psArgs = @(
    '-NoProfile', '-ExecutionPolicy', 'Bypass', '-File', $installerPath,
    '-Role', $Role, '-NodeName', $Node, '-Unattended'
)
if ($Dry) { $psArgs += '-DryRun' }
Write-Host "Running Install-HelmerAI.ps1 (unattended, local package)..." -ForegroundColor Cyan
$prev = $ErrorActionPreference
try {
    $ErrorActionPreference = 'Continue'
    & powershell.exe @psArgs
    $code = $LASTEXITCODE
} finally {
    $ErrorActionPreference = $prev
}
Remove-Item $stage -Recurse -Force -ErrorAction SilentlyContinue
Remove-Item $zip -Force -ErrorAction SilentlyContinue
Write-Host "Install exit $code. Log: $Root\install.log" -ForegroundColor $(if ($code -eq 0) { 'Green' } else { 'Yellow' })
if ($code -ne 0) { exit $code }
