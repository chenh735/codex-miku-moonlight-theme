[CmdletBinding()]
param(
  [ValidateRange(1024, 65535)][int]$Port = 9335,
  [switch]$NoShortcuts
)

$ErrorActionPreference = 'Stop'
$installer = Join-Path $PSScriptRoot 'windows\scripts\install-dream-skin.ps1'
if (-not (Test-Path -LiteralPath $installer -PathType Leaf)) {
  throw "Theme installer is missing: $installer"
}

& $installer @PSBoundParameters
