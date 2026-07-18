[CmdletBinding()]
param(
  [Parameter(Mandatory = $true)]
  [ValidatePattern('^\d+\.\d+\.\d+(?:-[0-9A-Za-z.-]+)?$')]
  [string]$Version,
  [string]$OutputDirectory = (Join-Path (Split-Path -Parent (Split-Path -Parent $PSScriptRoot)) 'dist'),
  [string]$RepositoryRoot = (Split-Path -Parent (Split-Path -Parent $PSScriptRoot))
)

$ErrorActionPreference = 'Stop'
Set-StrictMode -Version Latest

$repositoryRoot = [System.IO.Path]::GetFullPath($RepositoryRoot)
$resolvedOutput = [System.IO.Path]::GetFullPath($OutputDirectory)
[System.IO.Directory]::CreateDirectory($resolvedOutput) | Out-Null
$stage = Join-Path ([System.IO.Path]::GetTempPath()) "codex-miku-release-$PID-$([guid]::NewGuid().ToString('N'))"
$zipName = "codex-miku-moonlight-theme-$Version.zip"
$zipPath = Join-Path $resolvedOutput $zipName
$checksumPath = "$zipPath.sha256"

$files = @(
  'Install.ps1',
  'Restore.ps1',
  'README.md',
  'README.en.md',
  'LICENSE',
  'NOTICE.md',
  'CHANGELOG.md',
  'UPSTREAM.md',
  'docs\installation.md',
  'windows\README.md',
  'windows\README.en.md',
  'windows\CHANGELOG.md',
  'windows\SKILL.md'
)
$directories = @(
  'windows\assets',
  'windows\references',
  'windows\scripts'
)

try {
  New-Item -ItemType Directory -Path $stage | Out-Null
  foreach ($relative in $files) {
    $source = Join-Path $repositoryRoot $relative
    if (-not (Test-Path -LiteralPath $source -PathType Leaf)) {
      throw "Required release file is missing: $relative"
    }
    $destination = Join-Path $stage $relative
    [System.IO.Directory]::CreateDirectory([System.IO.Path]::GetDirectoryName($destination)) | Out-Null
    Copy-Item -LiteralPath $source -Destination $destination -Force
  }
  foreach ($relative in $directories) {
    $source = Join-Path $repositoryRoot $relative
    if (-not (Test-Path -LiteralPath $source -PathType Container)) {
      throw "Required release directory is missing: $relative"
    }
    $destination = Join-Path $stage $relative
    [System.IO.Directory]::CreateDirectory([System.IO.Path]::GetDirectoryName($destination)) | Out-Null
    Copy-Item -LiteralPath $source -Destination $destination -Recurse -Force
  }

  Remove-Item -LiteralPath $zipPath, $checksumPath -Force -ErrorAction SilentlyContinue
  Compress-Archive -Path (Join-Path $stage '*') -DestinationPath $zipPath -CompressionLevel Optimal
  $hash = (Get-FileHash -Algorithm SHA256 -LiteralPath $zipPath).Hash.ToLowerInvariant()
  [System.IO.File]::WriteAllText(
    $checksumPath,
    "$hash  $zipName`n",
    [System.Text.UTF8Encoding]::new($false)
  )
  Write-Host "Created $zipPath"
  Write-Host "Created $checksumPath"
} finally {
  if ([System.IO.Directory]::Exists($stage)) {
    Remove-Item -LiteralPath $stage -Recurse -Force -ErrorAction SilentlyContinue
  }
}
