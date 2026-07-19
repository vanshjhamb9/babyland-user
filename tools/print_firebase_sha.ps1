# Prints SHA-1 / SHA-256 for Firebase Console (Phone Auth, Google Sign-In).
# 1) Debug keystore (default for flutter run / many local release tests)
# 2) Gradle signingReport (debug + release variants — use the variant you ship)

$ErrorActionPreference = "Stop"

Write-Host "`n=== Debug keystore (Windows default) ===" -ForegroundColor Cyan
$debugKs = "$env:USERPROFILE\.android\debug.keystore"
if (Test-Path $debugKs) {
  keytool -list -v -keystore $debugKs -alias androiddebugkey -storepass android -keypass android
} else {
  Write-Host "Not found: $debugKs"
}

Write-Host "`n=== Gradle signingReport (run from android/) ===" -ForegroundColor Cyan
Write-Host "  cd android" 
Write-Host "  .\gradlew.bat signingReport" 
Write-Host "Copy SHA-1 and SHA-256 for BOTH debug and release into Firebase > Project settings > Your apps > Android."
Write-Host "Then download a NEW google-services.json -> android/app/google-services.json and reinstall the APK.`n"

$gsJson = Join-Path (Split-Path -Parent $PSScriptRoot) "android\app\google-services.json"
if (Test-Path $gsJson) {
  $raw = Get-Content $gsJson -Raw
  if ($raw -match '"certificate_hash":\s*"([a-f0-9]+)"') {
    Write-Host "google-services.json certificate_hash (SHA-1, no colons): $($Matches[1])" -ForegroundColor Yellow
    Write-Host "Must match the SHA-1 from signingReport above (ignore colons/case)." -ForegroundColor Yellow
  }
}

$Root = Split-Path -Parent $PSScriptRoot
$keyProps = Join-Path $Root "android\key.properties"
if (Test-Path $keyProps) {
  Write-Host "`n=== Release keystore (from key.properties) ===" -ForegroundColor Cyan
  $props = @{}
  Get-Content $keyProps | ForEach-Object {
    if ($_ -match '^\s*([^#=]+)=(.*)$') { $props[$Matches[1].Trim()] = $Matches[2].Trim() }
  }
  $storeFile = $props["storeFile"]
  $alias = $props["keyAlias"]
  $storePass = $props["storePassword"]
  if ($storeFile -and $alias -and $storePass) {
    $ksPath = Join-Path (Join-Path $Root "android") $storeFile
    if (Test-Path $ksPath) {
      keytool -list -v -keystore $ksPath -alias $alias -storepass $storePass -keypass $props["keyPassword"]
    } else {
      Write-Host "Keystore not found: $ksPath"
    }
  }
} else {
  Write-Host "`nNo android/key.properties — release builds still use DEBUG signing." -ForegroundColor Yellow
  Write-Host "For Play Console: .\tools\setup_release_keystore.ps1"
}
Write-Host ""
