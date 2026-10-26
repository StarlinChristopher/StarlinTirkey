[CmdletBinding()]
param(
    [string]$Volume = 'edgeblueprint_volatile_buffer',
    [int]$WarningBytes = [REDACTED],
    [int]$CriticalBytes = 966367641
)
$ErrorActionPreference = 'Stop'
$size = docker run --rm -v "${Volume}:/buffer:ro" alpine:3.23 sh -c "find /buffer -type f -printf '%s\n' 2>/dev/null | awk '{total += `$1} END {print total+0}'"
if ($LASTEXITCODE -ne 0) { throw 'Unable to inspect the telemetry buffer volume.' }
$bytes = [int64]$size.Trim()
$result = [ordered]@{ timestamp = (Get-Date).ToUniversalTime().ToString('o'); volume = $Volume; bytes = $bytes; warning_bytes = $WarningBytes; critical_bytes = $CriticalBytes }
if ($bytes -ge $CriticalBytes) { $result.level = 'critical'; $result.message = 'Telemetry buffer exceeds critical threshold'; $result | ConvertTo-Json -Compress; exit 2 }
if ($bytes -ge $WarningBytes) { $result.level = 'warning'; $result.message = 'Telemetry buffer exceeds warning threshold'; $result | ConvertTo-Json -Compress; exit 1 }
$result.level = 'ok'; $result.message = 'Telemetry buffer is within limits'; $result | ConvertTo-Json -Compress
