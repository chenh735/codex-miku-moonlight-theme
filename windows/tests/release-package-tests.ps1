$ErrorActionPreference = 'Stop'
Set-StrictMode -Version Latest

Add-Type -AssemblyName System.IO.Compression.FileSystem
$repositoryRoot = Split-Path -Parent (Split-Path -Parent $PSScriptRoot)
$packager = Join-Path $repositoryRoot 'windows\scripts\package-release.ps1'
$temporaryRoot = Join-Path ([System.IO.Path]::GetTempPath()) "miku-release-test-$PID-$([guid]::NewGuid().ToString('N'))"
$fixtureRoot = Join-Path $temporaryRoot 'fixture'
$outputRoot = Join-Path $temporaryRoot 'output'

function Assert-ReleaseContract {
  param([bool]$Condition, [string]$Message)
  if (-not $Condition) { throw $Message }
}

New-Item -ItemType Directory -Path $temporaryRoot | Out-Null
try {
  foreach ($relative in @(
      'Install.ps1', 'Restore.ps1', 'README.md', 'README.en.md', 'LICENSE', 'NOTICE.md',
      'CHANGELOG.md', 'UPSTREAM.md', 'docs\installation.md', 'windows\README.md',
      'windows\README.en.md', 'windows\CHANGELOG.md', 'windows\SKILL.md',
      'windows\assets\theme.json', 'windows\assets\miku-moonlight-hero.png',
      'windows\assets\miku-music-mark.ico', 'windows\references\runtime-notes.md',
      'windows\scripts\install-dream-skin.ps1', 'windows\scripts\restore-dream-skin.ps1'
    )) {
    $path = Join-Path $fixtureRoot $relative
    [System.IO.Directory]::CreateDirectory([System.IO.Path]::GetDirectoryName($path)) | Out-Null
    [System.IO.File]::WriteAllText($path, "fixture: $relative`n", [System.Text.UTF8Encoding]::new($false))
  }

  & $packager -Version '1.0.0-test.1' -OutputDirectory $outputRoot -RepositoryRoot $fixtureRoot
  $zipPath = Join-Path $outputRoot 'codex-miku-moonlight-theme-1.0.0-test.1.zip'
  $checksumPath = "$zipPath.sha256"
  Assert-ReleaseContract (Test-Path -LiteralPath $zipPath -PathType Leaf) 'Release ZIP was not created.'
  Assert-ReleaseContract (Test-Path -LiteralPath $checksumPath -PathType Leaf) 'Release checksum was not created.'

  $archive = [System.IO.Compression.ZipFile]::OpenRead($zipPath)
  try {
    $entries = @($archive.Entries | ForEach-Object { $_.FullName.Replace('\', '/') })
  } finally { $archive.Dispose() }

  foreach ($required in @(
      'Install.ps1',
      'Restore.ps1',
      'README.md',
      'README.en.md',
      'LICENSE',
      'NOTICE.md',
      'CHANGELOG.md',
      'UPSTREAM.md',
      'docs/installation.md',
      'windows/assets/theme.json',
      'windows/assets/miku-moonlight-hero.png',
      'windows/assets/miku-music-mark.ico',
      'windows/scripts/install-dream-skin.ps1',
      'windows/scripts/restore-dream-skin.ps1'
    )) {
    Assert-ReleaseContract ($entries -contains $required) "Release ZIP is missing: $required"
  }

  foreach ($forbiddenPattern in @(
      '^\.git/', '^\.github/', '^\.worktrees/', '^verification/', '^outputs/',
      '/tests/', '\.log$', 'settings\.json$', 'state\.json$', 'auth\.json$', '\.env$'
    )) {
    Assert-ReleaseContract (-not ($entries -match $forbiddenPattern)) "Release ZIP contains forbidden content: $forbiddenPattern"
  }

  $expectedHash = (Get-FileHash -Algorithm SHA256 -LiteralPath $zipPath).Hash.ToLowerInvariant()
  $checksum = [System.IO.File]::ReadAllText($checksumPath, [System.Text.UTF8Encoding]::new($false)).Trim()
  Assert-ReleaseContract ($checksum -ceq "$expectedHash  $([System.IO.Path]::GetFileName($zipPath))") `
    'Checksum file does not match the archive.'
  Write-Host 'PASS: release archive allowlist and checksum contracts.'
} finally {
  Remove-Item -LiteralPath $temporaryRoot -Recurse -Force -ErrorAction SilentlyContinue
}
