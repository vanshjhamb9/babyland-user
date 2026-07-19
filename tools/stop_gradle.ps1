# Stop Gradle daemons and clear common Windows lock files before a release build.
param(
    [int]$MaxWaitSeconds = 120
)

$ErrorActionPreference = "Stop"
$Root = Split-Path -Parent (Split-Path -Parent $MyInvocation.MyCommand.Path)
$AndroidDir = Join-Path $Root "android"
$GradleHome = if ($env:GRADLE_USER_HOME) { $env:GRADLE_USER_HOME } else { Join-Path $env:USERPROFILE ".gradle" }

function Stop-GradleDaemons {
    if (Test-Path (Join-Path $AndroidDir "gradlew.bat")) {
        Push-Location $AndroidDir
        & .\gradlew.bat --stop 2>$null | Out-Null
        Pop-Location
    }
}

function Stop-GradleJavaProcesses {
    Get-CimInstance Win32_Process -Filter "Name = 'java.exe'" -ErrorAction SilentlyContinue |
        Where-Object { $_.CommandLine -match "GradleDaemon|org\.gradle\.launcher|kotlin-compiler-daemon" } |
        ForEach-Object {
            Write-Host "Stopping Gradle Java process PID $($_.ProcessId)..."
            Stop-Process -Id $_.ProcessId -Force -ErrorAction SilentlyContinue
        }
}

function Wait-LockFree {
    param([string]$LockFile, [string]$Label)
    if (-not (Test-Path $LockFile)) { return $true }

    Write-Host "$Label lock present: $LockFile"
    $deadline = (Get-Date).AddSeconds($MaxWaitSeconds)
    while ((Get-Date) -lt $deadline) {
        if (-not (Test-Path $LockFile)) { return $true }
        Stop-GradleDaemons
        Stop-GradleJavaProcesses
        Start-Sleep -Seconds 5
    }

    if (Test-Path $LockFile) {
        Write-Host "Removing stale $Label lock (safe after gradlew --stop)..."
        Remove-Item -LiteralPath $LockFile -Force -ErrorAction SilentlyContinue
    }
    return -not (Test-Path $LockFile)
}

Write-Host "Stopping Gradle daemons..."
Stop-GradleDaemons
Start-Sleep -Seconds 3

$buildLogicLock = Join-Path $AndroidDir ".gradle\noVersion\buildLogic.lock"
$jarsLock = Join-Path $GradleHome "caches\jars-9\jars-9.lock"

$ok = $true
if (-not (Wait-LockFree -LockFile $buildLogicLock -Label "build-logic")) { $ok = $false }
if (-not (Wait-LockFree -LockFile $jarsLock -Label "jars-9")) { $ok = $false }

# Only kill Gradle Java processes if locks remain after waiting (avoid killing an active build).
if (-not $ok) {
    Stop-GradleJavaProcesses
    Start-Sleep -Seconds 2
    if (-not (Wait-LockFree -LockFile $buildLogicLock -Label "build-logic")) { $ok = $false }
    if (-not (Wait-LockFree -LockFile $jarsLock -Label "jars-9")) { $ok = $false }
}

if (-not $ok) {
    Write-Host "ERROR: Gradle locks still held. Close other builds, reload Cursor, then retry." -ForegroundColor Red
    exit 1
}

Write-Host "Gradle locks cleared." -ForegroundColor Green
