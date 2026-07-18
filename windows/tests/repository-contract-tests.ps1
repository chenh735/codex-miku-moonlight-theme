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

$readmeZh = Read-RepositoryUtf8 'README.md'
$readmeEn = Read-RepositoryUtf8 'README.en.md'
$notice = Read-RepositoryUtf8 'NOTICE.md'
$license = Read-RepositoryUtf8 'LICENSE'
$installation = Read-RepositoryUtf8 'docs\installation.md'
$upstream = Read-RepositoryUtf8 'UPSTREAM.md'
$opacityRange = '5%' + [char]0x2013 + '35%'
$mikuShortcut = 'Codex ' + (-join [char[]]@(0x521D, 0x97F3, 0x672A, 0x6765, 0x4E3B, 0x9898))
$submitIssue = (-join [char[]]@(0x63D0, 0x4EA4)) + ' Issue'

foreach ($required in @(
    '26.715.3651.0',
    'Node.js 22',
    '30%',
    $opacityRange,
    '.\Install.ps1',
    '.\Restore.ps1',
    $mikuShortcut,
    '%LOCALAPPDATA%\CodexMikuMoonlightTheme',
    '127.0.0.1'
  )) {
  Assert-RepositoryContract ($readmeZh.Contains($required)) "Chinese README is missing: $required"
}
foreach ($required in @(
    '26.715.3651.0',
    'Node.js 22',
    '30%',
    $opacityRange,
    '.\Install.ps1',
    '.\Restore.ps1',
    'Codex Miku Moonlight Theme',
    '%LOCALAPPDATA%\CodexMikuMoonlightTheme',
    '127.0.0.1'
  )) {
  Assert-RepositoryContract ($readmeEn.Contains($required)) "English README is missing: $required"
}
foreach ($stale in @('26.715.2305.0', '%LOCALAPPDATA%\CodexDreamSkin', 'Codex Dream Skin - Tray')) {
  Assert-RepositoryContract (-not $readmeZh.Contains($stale)) "Chinese README contains stale text: $stale"
  Assert-RepositoryContract (-not $readmeEn.Contains($stale)) "English README contains stale text: $stale"
}
foreach ($required in @('MIT License', 'Permission is hereby granted', 'THE SOFTWARE IS PROVIDED')) {
  Assert-RepositoryContract ($license.Contains($required)) "LICENSE is missing: $required"
}
foreach ($required in @(
    'unofficial, non-commercial fan theme',
    'OpenAI',
    'Crypton Future Media',
    'Hatsune Miku',
    'not covered by the MIT License',
    'Codex-Dream-Skin'
  )) {
  Assert-RepositoryContract ($notice.Contains($required)) "NOTICE is missing: $required"
}
Assert-RepositoryContract ($installation.Contains('9335')) 'Installation guide must document the default port.'
Assert-RepositoryContract ($installation.Contains('injector.log')) 'Installation guide must document the injector log.'
Assert-RepositoryContract ($installation.Contains($submitIssue)) 'Installation guide must explain issue reporting.'
Assert-RepositoryContract ($upstream.Contains('d4087e6e992b478f4626ba11e553f8bc19aea14f')) 'Pinned upstream commit changed.'

$workflow = Read-RepositoryUtf8 '.github\workflows\release.yml'
foreach ($required in @(
    "tags: ['v*']",
    'contents: write',
    'runs-on: windows-latest',
    'actions/checkout@v7',
    'actions/setup-node@v7',
    'node-version: 22',
    'shell: pwsh',
    'pwsh -NoProfile',
    'powershell.exe -NoProfile',
    '.\windows\tests\run-tests.ps1',
    '.\windows\tests\miku-contract-tests.ps1',
    '.\windows\tests\miku-product-contract-tests.ps1',
    '.\windows\scripts\package-release.ps1',
    'gh release create'
  )) {
  Assert-RepositoryContract ($workflow.Contains($required)) "Release workflow is missing: $required"
}
Assert-RepositoryContract (-not $workflow.Contains('pull_request_target')) 'Release workflow must not use pull_request_target.'
Assert-RepositoryContract (-not $workflow.Contains('0.0.0.0')) 'Release workflow must not weaken the loopback contract.'
Assert-RepositoryContract (-not $workflow.Contains('actions/checkout@v4')) 'Release workflow uses the deprecated checkout Node 20 runtime.'
Assert-RepositoryContract (-not $workflow.Contains('actions/setup-node@v4')) 'Release workflow uses the deprecated setup-node Node 20 runtime.'

Write-Host 'PASS: root repository entry-point contracts.'
