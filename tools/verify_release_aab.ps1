# Verify release AAB signing before Play Console upload.
param(
    [string]$AabPath = ""
)

$ErrorActionPreference = "Stop"
$Root = Split-Path -Parent (Split-Path -Parent $MyInvocation.MyCommand.Path)

if ([string]::IsNullOrWhiteSpace($AabPath)) {
    $AabPath = Join-Path $Root "build\app\outputs\bundle\release\app-release.aab"
}

$KeyProps = Join-Path $Root "android\key.properties"
$KeystorePath = Join-Path $Root "android\upload-keystore.jks"

Write-Host ""
Write-Host "=== Pre-build checks ===" -ForegroundColor Cyan

$checks = @()

if (Test-Path $KeyProps) {
    $checks += @{ Name = "key.properties"; Ok = $true }
} else {
    $checks += @{ Name = "key.properties"; Ok = $false }
}

if (Test-Path $KeystorePath) {
    $checks += @{ Name = "upload-keystore.jks"; Ok = $true }
} else {
    $checks += @{ Name = "upload-keystore.jks"; Ok = $false }
}

$gsJson = Join-Path $Root "android\app\google-services.json"
if (Test-Path $gsJson) {
    $checks += @{ Name = "google-services.json"; Ok = $true }
} else {
    $checks += @{ Name = "google-services.json"; Ok = $false }
}

foreach ($c in $checks) {
    $color = if ($c.Ok) { "Green" } else { "Red" }
    $status = if ($c.Ok) { "OK" } else { "MISSING" }
    Write-Host "  [$status] $($c.Name)" -ForegroundColor $color
}

$failedPre = $checks | Where-Object { -not $_.Ok }
if ($failedPre) {
    Write-Host ""
    Write-Host "Pre-build checks failed. Fix missing files before upload." -ForegroundColor Red
    exit 1
}

if (-not (Test-Path $AabPath)) {
    Write-Host ""
    Write-Host "AAB not found: $AabPath" -ForegroundColor Red
    exit 1
}

Write-Host ""
Write-Host "=== AAB file ===" -ForegroundColor Cyan
$item = Get-Item $AabPath
Write-Host "  Path: $($item.FullName)"
Write-Host ("  Size: {0:N2} MB" -f ($item.Length / 1MB))
Write-Host ("  Modified: {0}" -f $item.LastWriteTime)

# Load release keystore fingerprints for comparison.
$props = @{}
Get-Content $KeyProps | ForEach-Object {
    if ($_ -match '^\s*([^#=]+)=(.*)$') { $props[$Matches[1].Trim()] = $Matches[2].Trim() }
}
$storeFile = Join-Path (Join-Path $Root "android") $props["storeFile"]
$alias = $props["keyAlias"]
$storePass = $props["storePassword"]
$keyPass = $props["keyPassword"]

$keytoolPath = (Get-Command keytool -ErrorAction SilentlyContinue).Source
if (-not $keytoolPath) {
    $keytoolPath = Join-Path $env:JAVA_HOME "bin\keytool.exe"
}

Write-Host ""
Write-Host "=== Release keystore certificate ===" -ForegroundColor Cyan
$keystoreOut = & $keytoolPath -list -v -keystore $storeFile -alias $alias -storepass $storePass -keypass $keyPass 2>&1 | Out-String
$releaseSha1 = $null
$releaseSha256 = $null
if ($keystoreOut -match 'SHA1:\s*([0-9A-F:]+)') { $releaseSha1 = $Matches[1] }
if ($keystoreOut -match 'SHA256:\s*([0-9A-F:]+)') { $releaseSha256 = $Matches[1] }
if ($keystoreOut -match 'Owner:\s*(.+)') { Write-Host "  Owner: $($Matches[1].Trim())" }
if ($releaseSha1) { Write-Host "  SHA1: $releaseSha1" }
if ($releaseSha256) { Write-Host "  SHA256: $releaseSha256" }

Write-Host ""
Write-Host "=== AAB signature verification ===" -ForegroundColor Cyan

$jarsignerPath = (Get-Command jarsigner -ErrorAction SilentlyContinue).Source
if (-not $jarsignerPath) {
    $jarsignerPath = Join-Path $env:JAVA_HOME "bin\jarsigner.exe"
}

$verifyOut = & $jarsignerPath -verify -verbose -certs $AabPath 2>&1 | Out-String

if ($verifyOut -match 'jar verified') {
    Write-Host "  jarsigner: jar verified" -ForegroundColor Green
} else {
    Write-Host "  jarsigner: verification failed" -ForegroundColor Red
    Write-Host $verifyOut
    exit 1
}

$aabSha1 = $null
if ($verifyOut -match 'SHA1 digest:\s*([0-9A-Fa-f]+)') {
    $aabSha1 = ($Matches[1] -replace '(..)', '$1:' -replace ':$','').ToUpper()
}

# jarsigner cert block may include SHA1 fingerprint line
$aabCertSha1 = $null
if ($verifyOut -match 'Certificate fingerprint \(SHA1\):\s*([0-9A-F:]+)') {
    $aabCertSha1 = $Matches[1].ToUpper()
}

$isDebug = $verifyOut -match 'CN=Android Debug|ANDROIDDEBUGKEY|androiddebugkey'
if ($isDebug) {
    Write-Host "  FAIL: AAB is signed with DEBUG certificate" -ForegroundColor Red
    exit 1
}

Write-Host "  PASS: Not debug-signed" -ForegroundColor Green

if ($releaseSha1 -and $aabCertSha1) {
    $normRelease = ($releaseSha1 -replace ':','').ToUpper()
    $normAab = ($aabCertSha1 -replace ':','').ToUpper()
    if ($normRelease -eq $normAab) {
        Write-Host "  PASS: AAB certificate matches upload-keystore.jks" -ForegroundColor Green
    } else {
        Write-Host "  WARN: AAB cert SHA1 ($aabCertSha1) != keystore SHA1 ($releaseSha1)" -ForegroundColor Yellow
    }
}

Write-Host ""
Write-Host "=== Package name ===" -ForegroundColor Cyan
$bundletool = Get-Command bundletool -ErrorAction SilentlyContinue
if ($bundletool) {
    $manifest = & bundletool dump manifest --bundle=$AabPath 2>&1 | Out-String
    if ($manifest -match 'package="([^"]+)"') {
        $pkg = $Matches[1]
        Write-Host "  package: $pkg"
        if ($pkg -eq "com.thebabyland") {
            Write-Host "  PASS: Play Console package name" -ForegroundColor Green
        } else {
            Write-Host "  FAIL: expected com.thebabyland, got $pkg" -ForegroundColor Red
            exit 1
        }
    }
} else {
    Write-Host "  (install bundletool to verify package name automatically)"
}

Write-Host ""
Write-Host "Ready for Play Console upload." -ForegroundColor Green
Write-Host "  $AabPath"
Write-Host ""
