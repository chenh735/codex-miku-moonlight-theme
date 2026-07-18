$ErrorActionPreference = 'Stop'
Set-StrictMode -Version Latest

$repositoryRoot = Split-Path -Parent (Split-Path -Parent $PSScriptRoot)

function Assert-RepositoryContract {
  param(
    [Parameter(Mandatory = $true)][bool]$Condition,
    [Parameter(Mandatory = $true)][string]$Message
  )
  if (-not $Condition) { throw $Message }
}

function Read-RepositoryUtf8 {
  param([Parameter(Mandatory = $true)][string]$RelativePath)
  $path = Join-Path $repositoryRoot $RelativePath
  Assert-RepositoryContract (Test-Path -LiteralPath $path -PathType Leaf) "Missing repository file: $RelativePath"
  return [System.IO.File]::ReadAllText($path, [System.Text.UTF8Encoding]::new($false))
}

$install = Read-RepositoryUtf8 'Install.ps1'
$restore = Read-RepositoryUtf8 'Restore.ps1'

foreach ($requiredInstallText in @(
    '[ValidateRange(1024, 65535)]',
    "'windows\scripts\install-dream-skin.ps1'",
    '@PSBoundParameters'
  )) {
  Assert-RepositoryContract ($install.Contains($requiredInstallText)) "Install.ps1 is missing: $requiredInstallText"
}

foreach ($requiredRestoreText in @(
    '[ValidateRange(1024, 65535)]',
    "'windows\scripts\restore-dream-skin.ps1'",
    'RestoreBaseTheme = $true',
    '@forward'
  )) {
  Assert-RepositoryContract ($restore.Contains($requiredRestoreText)) "Restore.ps1 is missing: $requiredRestoreText"
}

foreach ($forbidden in @('ExecutionPolicy Bypass', 'WindowsApps', '.codex\config.toml')) {
  Assert-RepositoryContract (-not $install.Contains($forbidden)) "Root installer contains forbidden behavior: $forbidden"
  Assert-RepositoryContract (-not $restore.Contains($forbidden)) "Root restore contains forbidden behavior: $forbidden"
}

Write-Host 'PASS: root repository entry-point contracts.'
