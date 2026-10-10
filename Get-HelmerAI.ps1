# Helmer AI bootstrap 1.1.2 (secret-free, no GitHub sign-in).
# Optional one-liner: irm .../Get-HelmerAI.ps1 | iex
# Preferred: unzip HelmerAI-Install.zip and double-click Install-HelmerAI.bat (uses -File, not this script).
$ErrorActionPreference = 'Stop'
$ProgressPreference = 'SilentlyContinue'
$Role = if ($env:HELMERAI_ROLE) { $env:HELMERAI_ROLE } else { 'field' }
$Node = if ($env:HELMERAI_NODE) { $env:HELMERAI_NODE } else { 'surface' }
$Dry = [bool]($env:HELMERAI_DRYRUN -eq '1')
$Root = if ($env:HELMERAI_ROOT) { $env:HELMERAI_ROOT } else { 'C:\HelmerAI' }
$PkgUrl = if ($env:HELMERAI_PKG_URL) { $env:HELMERAI_PKG_URL } else {
    'https://github.com/jehelmer-oss/helmerai-bootstrap/releases/latest/download/HelmerAI-Install.zip'
}
$BootstrapVer = '1.1.2'

try {
    $id = [Security.Principal.WindowsIdentity]::GetCurrent()
    $prin = New-Object Security.Principal.WindowsPrincipal($id)
    $isAdmin = $prin.IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)
} catch { $isAdmin = $true }
if (-not $isAdmin) {
    $arg = '-NoProfile -ExecutionPolicy Bypass -Command "Invoke-RestMethod https://raw.githubusercontent.com/jehelmer-oss/helmerai-bootstrap/main/Get-HelmerAI.ps1 | Invoke-Expression"'
    Start-Process -Verb RunAs -FilePath powershell.exe -ArgumentList $arg | Out-Null
    return
}

Write-Host "Helmer AI bootstrap $BootstrapVer -> role=$Role node=$Node dry=$Dry" -ForegroundColor Cyan
New-Item -ItemType Directory -Path $Root -Force | Out-Null
$stage = Join-Path $env:TEMP ('helmerai-pkg-' + [guid]::NewGuid().ToString('n'))
$zip = Join-Path $env:TEMP 'HelmerAI-Install.zip'
New-Item -ItemType Directory -Path $stage -Force | Out-Null
Write-Host "Downloading package..." -ForegroundColor Cyan
Invoke-WebRequest -Uri $PkgUrl -OutFile $zip -UseBasicParsing
if (-not (Test-Path $zip) -or (Get-Item $zip).Length -lt 1000) { throw "package zip missing/too small: $zip" }
Expand-Archive -LiteralPath $zip -DestinationPath $stage -Force
$installer = Get-ChildItem -LiteralPath $stage -Recurse -Filter 'Install-HelmerAI.ps1' | Select-Object -First 1
if (-not $installer) { throw 'Install-HelmerAI.ps1 not found inside package' }
$local = Join-Path $Root 'src\windows-pkg'
if (Test-Path $local) { Remove-Item $local -Recurse -Force }
New-Item -ItemType Directory -Path (Split-Path $local) -Force | Out-Null
Copy-Item -LiteralPath $installer.DirectoryName -Destination $local -Recurse -Force
$installerPath = Join-Path $local 'Install-HelmerAI.ps1'
if (-not (Test-Path $installerPath)) {
    $installerPath = (Get-ChildItem -LiteralPath $local -Recurse -Filter 'Install-HelmerAI.ps1' | Select-Object -First 1).FullName
}
$psArgs = @('-NoProfile','-ExecutionPolicy','Bypass','-File',$installerPath,'-Role',$Role,'-NodeName',$Node,'-Unattended')
if ($Dry) { $psArgs += '-DryRun' }
Write-Host "Running via -File (not iex)..." -ForegroundColor Cyan
$prev = $ErrorActionPreference
try {
    $ErrorActionPreference = 'Continue'
    & powershell.exe @psArgs
    $code = $LASTEXITCODE
} finally { $ErrorActionPreference = $prev }
Remove-Item $stage -Recurse -Force -ErrorAction SilentlyContinue
Remove-Item $zip -Force -ErrorAction SilentlyContinue
Write-Host "Install exit $code. Log: $Root\install.log" -ForegroundColor $(if ($code -eq 0) { 'Green' } else { 'Yellow' })
if ($code -ne 0) { exit $code }
