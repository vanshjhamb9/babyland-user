# Release App Bundle (.aab) for Google Play Console — requires android/key.properties.
param(
    [switch]$SkipKeystoreCheck
)

$ErrorActionPreference = "Stop"
$Root = Split-Path -Parent (Split-Path -Parent $MyInvocation.MyCommand.Path)
$KeyProps = Join-Path $Root "android\key.properties"
$StopScript = Join-Path $Root "tools\stop_gradle.ps1"

Set-Location $Root

if (-not $SkipKeystoreCheck -and -not (Test-Path $KeyProps)) {
    Write-Host "ERROR: android/key.properties not found." -ForegroundColor Red
    Write-Host "Play Console rejects debug-signed builds. Run first:"
    Write-Host "  .\tools\setup_release_keystore.ps1`n"
    exit 1
}

& $StopScript
if ($LASTEXITCODE -ne 0) { exit $LASTEXITCODE }

$flutterArgs = @(
    "build", "appbundle", "--release",
    "--no-tree-shake-icons",
    "--target-platform", "android-arm64",
    "--dart-define=API_BASE_URL=http://164.52.197.176/api/v1",
    "--dart-define=API_ROOT_URL=http://164.52.197.176/api",
    "--dart-define=FIREBASE_FORCE_RECAPTCHA=false",
    "--dart-define=APP_BUILD_TAG=play-v1",
    "--dart-define=FIREBASE_APP_CHECK_ENABLED=false"
)

Write-Host "flutter $($flutterArgs -join ' ')..."
flutter @flutterArgs
if ($LASTEXITCODE -ne 0) { exit $LASTEXITCODE }

$out = Join-Path $Root "build\app\outputs\bundle\release\app-release.aab"
Write-Host "`nUpload this file to Play Console:" -ForegroundColor Green
Write-Host "  $out`n"
