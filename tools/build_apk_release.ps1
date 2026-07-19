# Release APK for low-RAM Windows. Logs diagnostics to debug-64f774.log (session 64f774).
param(
    [switch]$SplitPerAbi,
    [switch]$QuickMergeTest
)

$ErrorActionPreference = "Stop"
$Root = Split-Path -Parent (Split-Path -Parent $MyInvocation.MyCommand.Path)
$LogFile = Join-Path $Root "debug-64f774.log"
$RunId = if ($env:DEBUG_RUN_ID) { $env:DEBUG_RUN_ID } else { "pre-fix" }

function Write-AgentLog($hypothesisId, $location, $message, $data) {
    $dataPairs = ($data.GetEnumerator() | ForEach-Object { """$($_.Key)"":""$($_.Value)""" }) -join ","
    $ts = [DateTimeOffset]::UtcNow.ToUnixTimeMilliseconds()
    $line = "{""sessionId"":""64f774"",""runId"":""$RunId"",""hypothesisId"":""$hypothesisId"",""location"":""$location"",""message"":""$message"",""data"":{$dataPairs},""timestamp"":$ts}"
    Add-Content -Path $LogFile -Value $line -Encoding utf8
}

Set-Location $Root

$repoOnOneDrive = $Root -match 'OneDrive'
$javaCount = (Get-Process -Name "java" -ErrorAction SilentlyContinue | Measure-Object).Count
$sqfliteMergeDir = Join-Path $Root "build\sqflite_android\intermediates\incremental\release\mergeReleaseResources"

Write-AgentLog "H2" "build_apk_release.ps1:start" "preflight" @{
    repoOnOneDrive = $repoOnOneDrive
    javaProcessCount = $javaCount
    staleSharedMergeDirExists = (Test-Path $sqfliteMergeDir)
    projectRoot = $Root
}

function Wait-BuildLogicLockFree {
    param([string]$AndroidDir, [int]$MaxWaitSeconds = 120)
    $lockFile = Join-Path $AndroidDir ".gradle\noVersion\buildLogic.lock"
    if (-not (Test-Path $lockFile)) { return $true }

    Write-Host "Gradle build-logic lock present; stopping daemons..."
    Set-Location $AndroidDir
    & .\gradlew.bat --stop 2>$null | Out-Null
    Start-Sleep -Seconds 5

    if (-not (Test-Path $lockFile)) { return $true }

    # Cursor/VS Code Java language server often holds this lock during Gradle import.
    Write-Host "Removing stale buildLogic.lock (safe after gradlew --stop)..."
    Remove-Item -LiteralPath $lockFile -Force -ErrorAction SilentlyContinue
    if (-not (Test-Path $lockFile)) { return $true }

    $deadline = (Get-Date).AddSeconds($MaxWaitSeconds)
    while ((Get-Date) -lt $deadline) {
        if (-not (Test-Path $lockFile)) { return $true }
        Write-Host "Still waiting for lock..."
        & .\gradlew.bat --stop 2>$null | Out-Null
        Start-Sleep -Seconds 10
    }
    return -not (Test-Path $lockFile)
}

Write-Host "Stopping Gradle daemons..."
$AndroidDir = Join-Path $Root "android"
Push-Location $AndroidDir
& .\gradlew.bat --stop 2>$null
if (-not (Wait-BuildLogicLockFree -AndroidDir $AndroidDir)) {
    Write-Host "ERROR: Gradle lock still held. Reload Cursor window (Java import disabled in .vscode/settings.json) or close other Gradle builds, then retry."
    Write-AgentLog "H8" "build_apk_release.ps1:lock" "buildLogic lock timeout" @{ lockFile = (Join-Path $AndroidDir ".gradle\noVersion\buildLogic.lock") }
    Pop-Location
    exit 1
}

if (Test-Path $sqfliteMergeDir) {
    Write-Host "Removing stale shared mergeReleaseResources dir (legacy layout)..."
    Remove-Item -LiteralPath $sqfliteMergeDir -Recurse -Force -ErrorAction SilentlyContinue
    Write-AgentLog "H1" "build_apk_release.ps1:clean" "removed stale shared merge dir" @{
        path = $sqfliteMergeDir
        stillExists = (Test-Path $sqfliteMergeDir)
    }
}

if ($QuickMergeTest) {
    Write-Host "Quick test: :sqflite_android:mergeReleaseResources --rerun-tasks"
    & .\gradlew.bat :sqflite_android:mergeReleaseResources --rerun-tasks --no-daemon
    $code = $LASTEXITCODE
    Pop-Location
    Write-AgentLog "H3" "build_apk_release.ps1:quick" "merge-only finished" @{ exitCode = $code }
    if ($code -ne 0) { exit $code }
    Write-Host "Merge-only test passed."
    exit 0
}

Pop-Location

$flutterArgs = @(
    "build", "apk", "--release",
    "--no-tree-shake-icons",
    "--target-platform", "android-arm64",
    "--dart-define=API_BASE_URL=http://164.52.197.176/api/v1",
    "--dart-define=API_ROOT_URL=http://164.52.197.176/api",
    "--dart-define=FIREBASE_FORCE_RECAPTCHA=true",
    "--dart-define=APP_BUILD_TAG=otp-v5",
    "--dart-define=FIREBASE_APP_CHECK_ENABLED=false"
)
if ($SplitPerAbi) { $flutterArgs += "--split-per-abi" }

Write-Host "flutter $($flutterArgs -join ' ')..."
flutter @flutterArgs
if ($LASTEXITCODE -ne 0) {
    Write-AgentLog "H4" "build_apk_release.ps1:end" "flutter build failed" @{ exitCode = $LASTEXITCODE }
    exit $LASTEXITCODE
}

Write-AgentLog "H4" "build_apk_release.ps1:end" "flutter build succeeded" @{ exitCode = 0 }
$outDir = Join-Path $Root "build\app\outputs\flutter-apk"
Write-Host "APK output folder: $outDir"
Get-ChildItem $outDir -Filter "*.apk" -ErrorAction SilentlyContinue | ForEach-Object { Write-Host "  $($_.FullName)" }
