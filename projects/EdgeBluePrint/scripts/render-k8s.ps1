[CmdletBinding()]
param(
    [Parameter(Mandatory=$true)][string]$Owner,
    [Parameter(Mandatory=$true)][string]$Tag,
    [string]$Template = "$PSScriptRoot\..\k8s\edgeblueprint.yaml",
    [string]$Output = "$PSScriptRoot\..\k8s\edgeblueprint.rendered.yaml"
)
$ErrorActionPreference = 'Stop'
if ($Owner -notmatch '^[a-z0-9][a-z0-9-]{0,38}$') { throw 'Owner must be a lowercase GitHub owner or organization name.' }
if ($Tag -notmatch '^[A-Za-z0-9][A-Za-z0-9._-]{0,127}$') { throw 'Tag contains unsupported characters.' }
if (-not (Test-Path -LiteralPath $Template -PathType Leaf)) { throw "Template not found: $Template" }
$content = Get-Content -Raw -LiteralPath $Template
$content = $content.Replace('REPLACE_OWNER', $Owner).Replace('REPLACE_TAG', $Tag)
if ($content -match 'REPLACE_OWNER|REPLACE_TAG') { throw 'Unresolved Kubernetes image placeholders remain.' }
Set-Content -LiteralPath $Output -Value $content -Encoding utf8
Write-Output "Rendered Kubernetes manifest: $Output"
