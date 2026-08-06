# Verifies Android Firebase package / App ID / SHA alignment for Phone OTP.
# Run from repo root: powershell -ExecutionPolicy Bypass -File .\tools\verify_firebase_android_keys.ps1

$ErrorActionPreference = "Stop"
$Root = Split-Path -Parent (Split-Path -Parent $MyInvocation.MyCommand.Path)
$Gs = Join-Path $Root "android\app\google-services.json"
$Gradle = Join-Path $Root "android\app\build.gradle.kts"
$Opts = Join-Path $Root "lib\firebase_options.dart"
$KeyProps = Join-Path $Root "android\key.properties"

Write-Host "=== Babyland Firebase Android key audit ===" -ForegroundColor Cyan
Write-Host ""

$appIdLine = (Select-String -Path $Gradle -Pattern 'applicationId\s*=\s*"([^"]+)"').Matches[0].Groups[1].Value
Write-Host "applicationId (build.gradle.kts): $appIdLine"

$gs = Get-Content $Gs -Raw | ConvertFrom-Json
$gsProject = $gs.project_info.project_id
# Prefer the client that matches applicationId (multi-app JSON includes legacy packages).
$client = $gs.client | Where-Object {
  $_.client_info.android_client_info.package_name -eq $appIdLine
} | Select-Object -First 1
if (-not $client) {
  Write-Host "FAIL: no google-services.json client for package $appIdLine" -ForegroundColor Red
  Write-Host "Available packages:"
  $gs.client | ForEach-Object {
    Write-Host ("  - {0} ({1})" -f $_.client_info.android_client_info.package_name, $_.client_info.mobilesdk_app_id)
  }
  exit 1
}
$gsPkg = $client.client_info.android_client_info.package_name
$gsAppId = $client.client_info.mobilesdk_app_id
$gsKey = $client.api_key[0].current_key
Write-Host "google-services.json package:     $gsPkg"
Write-Host "google-services.json appId:       $gsAppId"
Write-Host "google-services.json apiKey:      $gsKey"
Write-Host "google-services.json project:     $gsProject"
Write-Host "clients in JSON: $($gs.client.Count)"

$optApp = (Select-String -Path $Opts -Pattern "appId:\s*'([^']+)'" | Select-Object -First 1).Matches[0].Groups[1].Value
$optKey = (Select-String -Path $Opts -Pattern "apiKey:\s*'([^']+)'" | Select-Object -First 1).Matches[0].Groups[1].Value
Write-Host "firebase_options.dart android appId: $optApp"
Write-Host "firebase_options.dart android apiKey: $optKey"

Write-Host ""
Write-Host "=== SHA fingerprints (must be in Firebase Console for this Android app) ===" -ForegroundColor Cyan

$debugKs = Join-Path $env:USERPROFILE ".android\debug.keystore"
if (Test-Path $debugKs) {
  Write-Host "DEBUG:"
  keytool -list -v -keystore $debugKs -alias androiddebugkey -storepass android -keypass android 2>&1 |
    Select-String 'SHA1:|SHA256:' | ForEach-Object { Write-Host "  $($_.Line.Trim())" }
}

if (Test-Path $KeyProps) {
  $props = @{}
  Get-Content $KeyProps | ForEach-Object {
    if ($_ -match '^\s*([^#=]+)=(.*)$') { $props[$Matches[1].Trim()] = $Matches[2].Trim() }
  }
  $store = Join-Path (Join-Path $Root "android") $props["storeFile"]
  if (-not (Test-Path $store)) { $store = Join-Path $Root $props["storeFile"] }
  Write-Host "RELEASE ($($props['storeFile'])):"
  keytool -list -v -keystore $store -alias $props["keyAlias"] -storepass $props["storePassword"] -keypass $props["keyPassword"] 2>&1 |
    Select-String 'SHA1:|SHA256:' | ForEach-Object { Write-Host "  $($_.Line.Trim())" }
}

$hashes = @($client.oauth_client | Where-Object { $_.android_info } | ForEach-Object { $_.android_info.certificate_hash })
Write-Host ""
Write-Host "certificate_hash entries for ${gsPkg}:"
$hashes | ForEach-Object { Write-Host "  $_" }

Write-Host ""
Write-Host "=== Checks ===" -ForegroundColor Cyan
$fail = 0
$need = @("447015d9c2e077b82a788aed5e70d2899d682fba", "2b570cf03613e3253d54bb6f36c88081fa095213")
foreach ($h in $need) {
  if ($hashes -contains $h) {
    Write-Host "OK: SHA-1 $h registered for ${gsPkg}" -ForegroundColor Green
  } else {
    Write-Host "FAIL: missing SHA-1 $h for ${gsPkg} (add in Firebase Console)" -ForegroundColor Red
    $fail++
  }
}
if ($appIdLine -ne $gsPkg) {
  Write-Host "FAIL: applicationId ($appIdLine) != google-services package ($gsPkg)" -ForegroundColor Red
  $fail++
} else {
  Write-Host "OK: applicationId matches google-services.json package" -ForegroundColor Green
}
if ($gsAppId -ne $optApp) {
  Write-Host "FAIL: google-services appId != firebase_options.dart appId" -ForegroundColor Red
  $fail++
} else {
  Write-Host "OK: firebase_options.dart appId matches google-services.json" -ForegroundColor Green
}
if ($gsKey -ne $optKey) {
  Write-Host "FAIL: API key mismatch between google-services.json and firebase_options.dart" -ForegroundColor Red
  $fail++
} else {
  Write-Host "OK: API keys match" -ForegroundColor Green
}

Write-Host ""
Write-Host "=== Production app wiring ===" -ForegroundColor Cyan
Write-Host "Using Android App ID: $gsAppId (package $gsPkg)"
Write-Host "Also keep SHA-256 in Firebase Console for this app (not stored in google-services.json)."
Write-Host "Then: .\tools\build_apk_release.ps1 && adb install -r build\app\outputs\flutter-apk\app-release.apk"
Write-Host ""

if ($fail -gt 0) { exit 1 }
Write-Host "GO: local Firebase Android config is aligned for $appIdLine." -ForegroundColor Green
