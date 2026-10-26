[CmdletBinding()]
param([string]$BackupFile = "$PSScriptRoot\..\backups\migration-check.sql")
$ErrorActionPreference = 'Stop'
if (-not (Test-Path -LiteralPath $BackupFile -PathType Leaf)) { throw "Backup file not found: $BackupFile" }
$version = docker exec epsumthings_db psql -U $env:POSTGRES_USER -d $env:POSTGRES_DB -Atc 'SHOW server_version_num'
if ($LASTEXITCODE -ne 0) { throw 'Unable to query PostgreSQL source version.' }
if ([int]$version -lt 180000 -or [int]$version -ge 190000) { throw "Expected PostgreSQL 18 source, got $version." }
$table = (docker exec epsumthings_db psql -U $env:POSTGRES_USER -d $env:POSTGRES_DB -Atc "SELECT to_regclass('public.telemetry')") -join ''
if ($LASTEXITCODE -ne 0) { throw 'Schema query failed.' }
if ($table.Trim() -ne 'telemetry') { throw 'Telemetry schema was not found in the source database.' }
Write-Output "PostgreSQL source version $version is dump-compatible for an offline restore into the DHI major version. Do not reuse the source volume directly."
