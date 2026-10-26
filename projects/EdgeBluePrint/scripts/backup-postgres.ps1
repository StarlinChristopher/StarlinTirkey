[CmdletBinding()]
param([string]$OutputDirectory = "$PSScriptRoot\..\backups")
$ErrorActionPreference = 'Stop'
New-Item -ItemType Directory -Force -Path $OutputDirectory | Out-Null
$stamp = Get-Date -Format 'yyyyMMdd-HHmmss'
$file = Join-Path $OutputDirectory "telemetry-$stamp.sql"
docker exec epsumthings_db pg_dump -U $env:POSTGRES_USER -d $env:POSTGRES_DB --format=plain --no-owner --no-privileges | Set-Content -Encoding utf8 $file
if ($LASTEXITCODE -ne 0) { throw 'PostgreSQL backup failed.' }
Write-Output "Backup created: $file"
