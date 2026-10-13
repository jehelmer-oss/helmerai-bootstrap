# Helmer AI bootstrap 1.1.127 (secret-free, no GitHub sign-in).
# Optional one-liner: unique TEMP file + -File (never a fixed Get-HelmerAI.ps1 path, never iex).
# Preferred: unzip HelmerAI-Install.zip and double-click Install-HelmerAI.bat (uses -File, not this script).
$ErrorActionPreference = 'Stop'
$ProgressPreference = 'SilentlyContinue'
# Role/node are passed only when set: the installer derives them from this PC's name and saved node.json.
$Role = $env:HELMERAI_ROLE
$Node = $env:HELMERAI_NODE
# Interactive by default so the RustDesk password, Tailscale sign-in and auto-login steps run. HELMERAI_UNATTENDED=1 opts out.
$Unattended = [bool]($env:HELMERAI_UNATTENDED -eq '1')
$Dry = [bool]($env:HELMERAI_DRYRUN -eq '1')
$Root = if ($env:HELMERAI_ROOT) { $env:HELMERAI_ROOT } else { 'C:\HelmerAI' }
$PkgUrl = if ($env:HELMERAI_PKG_URL) { $env:HELMERAI_PKG_URL } else {
    'https://github.com/jehelmer-oss/helmerai-bootstrap/releases/latest/download/HelmerAI-Install.zip'
}
$BootstrapVer = '1.1.127'

try {
    $id = [Security.Principal.WindowsIdentity]::GetCurrent()
    $prin = New-Object Security.Principal.WindowsPrincipal($id)
    $isAdmin = $prin.IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)
} catch { $isAdmin = $true }
if (-not $isAdmin) {
    $src = $PSCommandPath
    if (-not $src -or -not (Test-Path -LiteralPath $src) -or (Get-Item -LiteralPath $src).Length -lt 200) {
        $src = Join-Path $env:TEMP ("Get-HelmerAI-" + [guid]::NewGuid().ToString() + ".ps1")
        Invoke-RestMethod 'https://github.com/jehelmer-oss/helmerai-bootstrap/releases/latest/download/Get-HelmerAI.ps1' -OutFile $src
        if (-not (Test-Path -LiteralPath $src) -or (Get-Item -LiteralPath $src).Length -lt 200) { throw "bootstrap download failed: $src" }
    }
    try {
        $child = Start-Process -Verb RunAs -FilePath powershell.exe -ArgumentList @('-NoProfile','-ExecutionPolicy','Bypass','-File',('"' + $src + '"')) -Wait -PassThru
        exit $child.ExitCode
    } catch { Write-Error "Administrator approval was canceled or elevation failed: $($_.Exception.Message)"; exit 1 }
}

Write-Host "Helmer AI bootstrap $BootstrapVer -> role=$(if ($Role) { $Role } else { 'auto' }) node=$(if ($Node) { $Node } else { 'auto' }) unattended=$Unattended dry=$Dry" -ForegroundColor Cyan
New-Item -ItemType Directory -Path $Root -Force | Out-Null
$stage = Join-Path $env:TEMP ('helmerai-pkg-' + [guid]::NewGuid().ToString('n'))
$zip = Join-Path $env:TEMP ('HelmerAI-Install-' + [guid]::NewGuid().ToString('n') + '.zip')
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
$psArgs = @('-NoProfile','-ExecutionPolicy','Bypass','-File',$installerPath)
if ($Role) { $psArgs += @('-Role', $Role) }
if ($Node) { $psArgs += @('-NodeName', $Node) }
if ($Unattended) { $psArgs += '-Unattended' }
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
