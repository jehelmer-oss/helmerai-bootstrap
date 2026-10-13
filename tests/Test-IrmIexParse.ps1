# Parse Get-HelmerAI.ps1 the same way `irm <raw url> | iex` does on Windows PowerShell 5.1.
# Does not execute the installer: [scriptblock]::Create is the parse step iex uses.
$ErrorActionPreference = 'Stop'
if ($PSVersionTable.PSVersion.Major -ne 5) {
    throw "This test must run under Windows PowerShell 5.1 (powershell.exe). Got $($PSVersionTable.PSVersion)"
}

$testsDir = $PSScriptRoot
$repoRoot = Split-Path -Parent $testsDir
$targets = @(
    @{ Rel = 'Get-HelmerAI.ps1'; Required = $true }
    @{ Rel = 'release/Get-HelmerAI.ps1'; Required = $false }
)

$port = 18080
$bind = '127.0.0.1'
$py = $null
foreach ($name in @('python', 'python3', 'py')) {
    $cmd = Get-Command $name -ErrorAction SilentlyContinue
    if ($cmd) { $py = $cmd.Source; break }
}
if (-not $py) { throw 'python is required to serve .ps1 bytes like GitHub raw' }

$serve = Join-Path $testsDir 'serve_raw.py'
$proc = Start-Process -FilePath $py -ArgumentList @($serve, '--bind', $bind, '--port', "$port", '--root', $repoRoot) -PassThru -WindowStyle Hidden
$ready = $false
foreach ($i in 1..20) {
    if ($proc.HasExited) { throw "raw HTTP server exited early (code $($proc.ExitCode))" }
    try {
        $null = Invoke-WebRequest -Uri "http://$bind`:$port/Get-HelmerAI.ps1" -UseBasicParsing -TimeoutSec 2
        $ready = $true
        break
    } catch {
        Start-Sleep -Milliseconds 250
    }
}
if (-not $ready) { throw 'raw HTTP server did not become ready on 127.0.0.1:18080' }

function Test-IrmParse {
    param(
        [string]$Url,
        [string]$Label,
        [switch]$ExpectBomFailure
    )
    $content = Invoke-RestMethod -Uri $Url
    if ($null -eq $content) { throw "$Label : irm returned null" }
    $text = [string]$content
    $hasBom = ($text.Length -gt 0 -and [int][char]$text[0] -eq 0xFEFF)
    $tokens = $null
    $errors = $null
    [void][System.Management.Automation.Language.Parser]::ParseInput($text, [ref]$tokens, [ref]$errors)
    $parseFail = $errors -and $errors.Count -gt 0
    $createFail = $false
    $createErr = $null
    try {
        [void][scriptblock]::Create($text)
    } catch {
        $createFail = $true
        $createErr = $_.Exception.Message
    }
    if ($ExpectBomFailure) {
        if (-not ($hasBom -or $parseFail -or $createFail)) {
            throw "$Label : expected BOM/parse failure, but irm string parsed cleanly"
        }
        Write-Host "OK negative $Label (BOM leaked=$hasBom parseErr=$parseFail createErr=$createFail)"
        return
    }
    if ($hasBom) {
        throw "$Label : irm returned a leading U+FEFF BOM. Windows PowerShell 5.1 iex fails with 'Missing argument in parameter list'."
    }
    if ($parseFail) {
        throw "$Label : parse failed: $($errors[0].ToString())"
    }
    if ($createFail) {
        throw "$Label : [scriptblock]::Create (iex parse) failed: $createErr"
    }
    Write-Host "OK irm-parse $Label ($($text.Length) chars, PS $($PSVersionTable.PSVersion))"
}

try {
    Write-Host "Windows PowerShell $($PSVersionTable.PSVersion) $($PSVersionTable.PSEdition)"
    foreach ($t in $targets) {
        $path = Join-Path $repoRoot ($t.Rel -replace '/', [IO.Path]::DirectorySeparatorChar)
        if (-not (Test-Path -LiteralPath $path)) {
            if ($t.Required) { throw "missing $($t.Rel)" }
            continue
        }
        $url = "http://$bind`:$port/$($t.Rel)"
        Test-IrmParse -Url $url -Label $t.Rel
    }

    $good = Join-Path $repoRoot 'Get-HelmerAI.ps1'
    $bomCopy = Join-Path $env:TEMP 'Get-HelmerAI-bom.ps1'
    $bytes = [IO.File]::ReadAllBytes($good)
    if ($bytes.Length -ge 3 -and $bytes[0] -eq 0xEF -and $bytes[1] -eq 0xBB -and $bytes[2] -eq 0xBF) {
        throw 'Get-HelmerAI.ps1 on disk still starts with a UTF-8 BOM'
    }
    $withBom = New-Object byte[] ($bytes.Length + 3)
    $withBom[0] = 0xEF; $withBom[1] = 0xBB; $withBom[2] = 0xBF
    [System.Buffer]::BlockCopy($bytes, 0, $withBom, 3, $bytes.Length)
    [IO.File]::WriteAllBytes($bomCopy, $withBom)
    Copy-Item -LiteralPath $bomCopy -Destination (Join-Path $repoRoot 'Get-HelmerAI-bom.ps1') -Force
    try {
        Test-IrmParse -Url "http://$bind`:$port/Get-HelmerAI-bom.ps1" -Label 'BOM fixture' -ExpectBomFailure
    } finally {
        Remove-Item -LiteralPath (Join-Path $repoRoot 'Get-HelmerAI-bom.ps1') -Force -ErrorAction SilentlyContinue
        Remove-Item -LiteralPath $bomCopy -Force -ErrorAction SilentlyContinue
    }
} finally {
    if (-not $proc.HasExited) { Stop-Process -Id $proc.Id -Force }
}
