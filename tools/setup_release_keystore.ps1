# Creates android/upload-keystore.jks + android/key.properties for Play Console upload.
# Run from repo root:
#   powershell -ExecutionPolicy Bypass -File .\tools\setup_release_keystore.ps1
# Or double-click: tools\setup_release_keystore.cmd
param(
    [string]$Alias = "upload",
    [string]$KeystoreName = "upload-keystore.jks",
    [int]$ValidityDays = 10000
)

$ErrorActionPreference = "Stop"
$Root = Split-Path -Parent (Split-Path -Parent $MyInvocation.MyCommand.Path)
$AndroidDir = Join-Path $Root "android"
$KeystorePath = Join-Path $AndroidDir $KeystoreName
$KeyPropsPath = Join-Path $AndroidDir "key.properties"

function Read-PlainPassword {
    param([string]$Prompt)
    $secure = Read-Host $Prompt -AsSecureString
    [Runtime.InteropServices.Marshal]::PtrToStringAuto(
        [Runtime.InteropServices.Marshal]::SecureStringToBSTR($secure)
    )
}

if (Test-Path $KeystorePath) {
    Write-Host "Keystore already exists: $KeystorePath" -ForegroundColor Yellow
    Write-Host "Delete it first if you want a new one (only for brand-new apps)."
    exit 1
}

if (Test-Path $KeyPropsPath) {
    Write-Host "key.properties already exists: $KeyPropsPath" -ForegroundColor Yellow
    exit 1
}

Write-Host ""
Write-Host "=== Release keystore setup (Play Console) ===" -ForegroundColor Cyan
Write-Host "Choose a strong password and save it. You need it for every future app update."
Write-Host ""

$storePlain = Read-PlainPassword "Store password (min 6 characters)"
if ($storePlain.Length -lt 6) {
    Write-Host "Password must be at least 6 characters." -ForegroundColor Red
    exit 1
}

Write-Host "Key password (press Enter to use the same as store password):"
$keyInput = Read-Host "Key password"
$keyPlain = if ([string]::IsNullOrWhiteSpace($keyInput)) { $storePlain } else { $keyInput }

$keytoolPath = $null
$keytoolCmd = Get-Command keytool -ErrorAction SilentlyContinue
if ($keytoolCmd) {
    $keytoolPath = $keytoolCmd.Source
} else {
    $javaHomeKeytool = Join-Path $env:JAVA_HOME "bin\keytool.exe"
    if (Test-Path $javaHomeKeytool) { $keytoolPath = $javaHomeKeytool }
}

if (-not $keytoolPath) {
    Write-Host "keytool not found. Install JDK or set JAVA_HOME." -ForegroundColor Red
    exit 1
}

$dn = "CN=Babyland, OU=Mobile, O=Babyland, L=Unknown, ST=Unknown, C=IN"
Write-Host ""
Write-Host "Creating keystore..." -ForegroundColor Cyan

& $keytoolPath @(
    "-genkeypair",
    "-v",
    "-keystore", $KeystorePath,
    "-alias", $Alias,
    "-keyalg", "RSA",
    "-keysize", "2048",
    "-validity", $ValidityDays,
    "-dname", $dn,
    "-storepass", $storePlain,
    "-keypass", $keyPlain
)
if ($LASTEXITCODE -ne 0) { exit $LASTEXITCODE }

$props = @(
    "storePassword=$storePlain"
    "keyPassword=$keyPlain"
    "keyAlias=$Alias"
    "storeFile=$KeystoreName"
) -join "`n"

Set-Content -Path $KeyPropsPath -Value $props -Encoding utf8NoBOM -NoNewline

Write-Host ""
Write-Host "Created:" -ForegroundColor Green
Write-Host "  $KeystorePath"
Write-Host "  $KeyPropsPath"

Write-Host ""
Write-Host "=== SHA fingerprints (add BOTH to Firebase) ===" -ForegroundColor Cyan
& $keytoolPath -list -v -keystore $KeystorePath -alias $Alias -storepass $storePlain -keypass $keyPlain

Write-Host ""
Write-Host "Next steps:" -ForegroundColor Yellow
Write-Host "  1. Firebase -> Project settings -> Android (com.thebabyland) -> add SHA-1 and SHA-256 above"
Write-Host "  2. Download new google-services.json -> android/app/google-services.json"
Write-Host "  3. .\tools\stop_gradle.ps1"
Write-Host "  4. .\tools\build_appbundle_release.ps1"
Write-Host "  5. Upload build\app\outputs\bundle\release\app-release.aab to Play Console"
Write-Host "  6. Back up upload-keystore.jks and passwords outside git"
Write-Host ""
