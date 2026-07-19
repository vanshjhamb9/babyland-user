# Quick probe for consultation checkout readiness on the API host.
# Usage: .\tools\check_consultation_server.ps1
#        .\tools\check_consultation_server.ps1 -BaseUrl "http://164.52.197.176"

param(
    [string]$BaseUrl = "http://164.52.197.176"
)

$ErrorActionPreference = "Stop"
$root = Split-Path -Parent $PSScriptRoot

Write-Host "=== Babyland consultation server check ===" -ForegroundColor Cyan
Write-Host "Base URL: $BaseUrl`n"

function Invoke-JsonGet($path) {
    $uri = "$BaseUrl$path"
    try {
        return Invoke-RestMethod -Uri $uri -Method Get -TimeoutSec 15
    } catch {
        Write-Host "FAIL $path : $($_.Exception.Message)" -ForegroundColor Red
        return $null
    }
}

$health = Invoke-JsonGet "/health"
if ($health) {
    Write-Host "GET /health -> status=$($health.status)" -ForegroundColor Green
    if ($health.services.consultationPostgres) {
        $pg = $health.services.consultationPostgres
        Write-Host "  consultationPostgres: $($pg.status) - $($pg.message)"
    }
}

$debugRaw = Invoke-JsonGet "/api/v1/debug/system-health"
$debug = $null
if ($debugRaw) {
    if ($debugRaw.data) { $debug = $debugRaw.data } else { $debug = $debugRaw }
}
if ($debug) {
    Write-Host "`nGET /api/v1/debug/system-health" -ForegroundColor Green
    Write-Host "  postgresConnected: $($debug.postgresConnected)"
    $pgErr = $debug.postgresLastError
    if (-not $pgErr -and $debug.details) { $pgErr = $debug.details.postgresLastError }
    Write-Host "  postgresLastError: $pgErr"
    Write-Host "  mongoConnected:    $($debug.mongoConnected)"
}

if ($debug -and -not $debug.postgresConnected) {
    Write-Host "`nConsultation booking will fail until PostgreSQL is fixed on the server:" -ForegroundColor Yellow
    Write-Host "  1. Install/start PostgreSQL OR set CONSULTATION_DATABASE_URL to a reachable host (not localhost if PG is remote)."
    Write-Host "  2. On the Node server: cd Baby-Land-Node-Server-main; npm run migrate:pg"
    Write-Host "  3. Restart Node and re-run this script until postgresConnected is true."
    exit 1
}

Write-Host "`nConsultation PostgreSQL looks reachable from the API." -ForegroundColor Green
exit 0
