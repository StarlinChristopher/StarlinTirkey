[CmdletBinding()]
param(
    [string]$BaseUrl = 'https://localhost',
    [string]$TokenFile = (Join-Path $PSScriptRoot '..\config\api\telemetry_api_token.txt')
)

$ErrorActionPreference = 'Stop'

if (-not (Test-Path -LiteralPath $TokenFile -PathType Leaf)) {
    throw "Token file not found: $TokenFile"
}

$token = (Get-Content -LiteralPath $TokenFile -Raw).Trim()
if ([string]::IsNullOrWhiteSpace($token)) {
    throw 'Telemetry token file is empty.'
}

function Invoke-SmokeRequest {
    param(
        [string[]]$Arguments
    )

    $output = & curl.exe @Arguments
    if ($LASTEXITCODE -ne 0) {
        throw "Smoke request failed with curl exit code $LASTEXITCODE."
    }
    return ($output -join "`n")
}

# The bundled local certificate is self-signed; -k is for local smoke tests only.
$health = Invoke-SmokeRequest @('-k', '--fail-with-body', '--silent', '--show-error', "$BaseUrl/health")
$healthJson = $health | ConvertFrom-Json
if ($healthJson.status -ne 'ok') {
    throw "Health check failed: $health"
}

$payloadPath = Join-Path $env:TEMP "edgeblueprint-smoke-$PID.json"
try {
    @{ sensorId = 'smoke-test'; temperature = 21.5 } | ConvertTo-Json -Compress | Set-Content -LiteralPath $payloadPath -NoNewline
    $telemetry = Invoke-SmokeRequest @('-k', '--fail-with-body', '--silent', '--show-error', '-X', 'POST', "$BaseUrl/telemetry", '-H', "Authorization: Bearer $token", '-H', 'Content-Type: application/json', '--data-binary', "@$payloadPath")
    $telemetryJson = $telemetry | ConvertFrom-Json
} finally {
    Remove-Item -LiteralPath $payloadPath -Force -ErrorAction SilentlyContinue
}
if ($telemetryJson.status -ne 'ACCEPTED') {
    throw "Telemetry check failed: $telemetry"
}

Write-Output 'API smoke tests passed: /health and authenticated /telemetry'
