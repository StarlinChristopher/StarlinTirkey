[CmdletBinding()]
param([string]$BackupFile = "$PSScriptRoot\..\backups\migration-check.sql")
$ErrorActionPreference = 'Stop'
if (-not (Test-Path -LiteralPath $BackupFile -PathType Leaf)) { throw "Backup file not found: $BackupFile" }
$version = docker exec epsumthings_db psql -U $env:POSTGRES_USER -d $env:POSTGRES_DB -Atc 'SHOW server_version_num'
if ($LASTEXITCODE -ne 0) { throw 'Unable to query PostgreSQL source version.' }
if ([int]$version -lt 150000 -or [int]$version -ge 160000) { throw "Expected PostgreSQL 15 source, got $version." }
$schema = docker exec epsumthings_db pg_dump -U $env:POSTGRES_USER -d $env:POSTGRES_DB --schema-only --no-owner --no-privileges
if ($LASTEXITCODE -ne 0) { throw 'Schema dump failed.' }
if ($schema -notmatch '(?i)CREATE TABLE (public\.)?telemetry') { throw 'Telemetry schema was not found in the source dump.' }
Write-Output "PostgreSQL source version $version is dump-compatible for an offline restore into the DHI major version. Do not reuse the source volume directly."
