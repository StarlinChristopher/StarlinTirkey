[CmdletBinding()]
param([Parameter(Mandatory=$true)][string]$BackupFile)
$ErrorActionPreference = 'Stop'
if (-not (Test-Path -LiteralPath $BackupFile -PathType Leaf)) { throw "Backup file not found: $BackupFile" }
Get-Content -Raw -LiteralPath $BackupFile | docker exec -i epsumthings_db psql -U $env:POSTGRES_USER -d $env:POSTGRES_DB
if ($LASTEXITCODE -ne 0) { throw 'PostgreSQL restore failed.' }
Write-Output 'PostgreSQL restore completed.'
