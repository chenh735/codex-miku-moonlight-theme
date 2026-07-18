[CmdletBinding()]
param(
  [ValidateRange(1024, 65535)][int]$Port = 9335,
  [switch]$Uninstall,
  [switch]$PromptRestart,
  [switch]$ForceRestart,
  [switch]$NoRelaunch
)

$ErrorActionPreference = 'Stop'
$restore = Join-Path $PSScriptRoot 'windows\scripts\restore-dream-skin.ps1'
if (-not (Test-Path -LiteralPath $restore -PathType Leaf)) {
  throw "Theme restore script is missing: $restore"
}

$forward = @{
  Port = $Port
  RestoreBaseTheme = $true
}
foreach ($name in @('Uninstall', 'PromptRestart', 'ForceRestart', 'NoRelaunch')) {
  if ($PSBoundParameters.ContainsKey($name)) { $forward[$name] = $true }
}

& $restore @forward
