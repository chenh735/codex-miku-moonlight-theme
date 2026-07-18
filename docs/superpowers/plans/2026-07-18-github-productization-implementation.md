# Codex Miku Moonlight Theme GitHub Productization Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Turn the working Windows Miku theme into a public, bilingual, one-command-install GitHub repository with tested release packaging and an automatically published `v1.0.0` Release.

**Architecture:** Stable root `Install.ps1` and `Restore.ps1` entry points delegate to the existing Windows implementation, while a new whitelist packager produces a reviewable user ZIP and SHA-256 file. Repository contract tests protect product names, documentation, legal notices, workflow behavior, and archive contents; a Windows GitHub Actions job runs the complete suite before publishing any `v*` tag.

**Tech Stack:** Windows PowerShell 5.1, Node.js 22+, Git, GitHub Actions on `windows-latest`, GitHub CLI for initial repository creation and Release verification.

## Global Constraints

- Repository name: `codex-miku-moonlight-theme`.
- Repository visibility: public, under the currently authenticated personal GitHub account.
- Default branch: `main`.
- First release: `v1.0.0`.
- Platform: Windows with the official Microsoft Store `OpenAI.Codex` desktop app.
- Verified Codex version: `26.715.3651.0`; do not claim other versions are verified.
- Runtime requirement: Node.js 22 or newer.
- Default task-page background opacity: 30%; adjustable range remains 5%–35%.
- Keep the existing theme on both home and task pages.
- Do not modify WindowsApps, `app.asar`, the Codex signature, API/model settings, or `%USERPROFILE%\.codex\config.toml`.
- Do not add a service, scheduled task, Run-registry value, autostart entry, or persistent tray launcher.
- CDP must bind only to `127.0.0.1`.
- Root documentation is Chinese-first in `README.md`, with equivalent English documentation in `README.en.md`.
- The MIT license applies to software code only; character artwork, trademarks, and third-party assets remain excluded from that grant.

---

## File structure

- Create `Install.ps1`: stable root installation wrapper.
- Create `Restore.ps1`: stable root restore/uninstall wrapper.
- Create `README.md`: Chinese repository landing page.
- Create `README.en.md`: equivalent English landing page.
- Delete `README.zh-CN.md`: replaced by the conventional root `README.md`.
- Create `LICENSE`: MIT software license with preserved upstream attribution.
- Create `NOTICE.md`: upstream, trademark, character-art, third-party-asset, and non-endorsement notice.
- Create `CHANGELOG.md`: repository-level semantic-version history starting at `1.0.0`.
- Create `docs/installation.md`: detailed Chinese installation, settings, logs, recovery, and troubleshooting guide.
- Create `docs/screenshots/.gitkeep`: stable screenshot directory until approved real screenshots are added.
- Create `windows/scripts/package-release.ps1`: whitelist-based ZIP and SHA-256 builder.
- Create `windows/tests/repository-contract-tests.ps1`: root API, documentation, notice, and workflow contracts.
- Create `windows/tests/release-package-tests.ps1`: archive allowlist and checksum tests.
- Create `.github/workflows/release.yml`: tag-triggered Windows test, package, and Release workflow.
- Modify `windows/tests/run-tests.ps1`: invoke both new repository-level tests.
- Replace `windows/README.md`: product-specific Chinese source/developer guide.
- Replace `windows/README.en.md`: product-specific English source/developer guide.
- Modify `windows/SKILL.md`: replace legacy product names, paths, and removed tray behavior with the Miku product contract.
- Replace `windows/CHANGELOG.md`: retain relevant provenance while making `1.0.0` the public product release.
- Modify `UPSTREAM.md`: link the upstream code license and notice while preserving the pinned commit.

---

### Task 1: Add stable root install and restore entry points

**Files:**
- Create: `windows/tests/repository-contract-tests.ps1`
- Create: `Install.ps1`
- Create: `Restore.ps1`
- Modify: `windows/tests/run-tests.ps1`

**Interfaces:**
- Consumes: `windows/scripts/install-dream-skin.ps1` parameters `Port:int` and `NoShortcuts:switch`.
- Consumes: `windows/scripts/restore-dream-skin.ps1` parameters `Port:int`, `Uninstall:switch`, `RestoreBaseTheme:switch`, `PromptRestart:switch`, `ForceRestart:switch`, and `NoRelaunch:switch`.
- Produces: root commands `./Install.ps1 [-Port <1024..65535>] [-NoShortcuts]` and `./Restore.ps1 [-Port <1024..65535>] [-Uninstall] [-PromptRestart] [-ForceRestart] [-NoRelaunch]`.

- [ ] **Step 1: Write the failing root entry-point contracts**

Create `windows/tests/repository-contract-tests.ps1`:

```powershell
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
    "[ValidateRange(1024, 65535)]",
    "'windows\scripts\install-dream-skin.ps1'",
    '@PSBoundParameters'
  )) {
  Assert-RepositoryContract ($install.Contains($requiredInstallText)) "Install.ps1 is missing: $requiredInstallText"
}

foreach ($requiredRestoreText in @(
    "[ValidateRange(1024, 65535)]",
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
```

- [ ] **Step 2: Run the contract and verify it fails**

Run:

```powershell
powershell.exe -NoProfile -ExecutionPolicy Bypass -File .\windows\tests\repository-contract-tests.ps1
```

Expected: FAIL with `Missing repository file: Install.ps1`.

- [ ] **Step 3: Implement the root installation wrapper**

Create `Install.ps1`:

```powershell
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
```

- [ ] **Step 4: Implement the root restore wrapper**

Create `Restore.ps1`:

```powershell
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
```

- [ ] **Step 5: Run the focused contract**

Run:

```powershell
powershell.exe -NoProfile -ExecutionPolicy Bypass -File .\windows\tests\repository-contract-tests.ps1
```

Expected: `PASS: root repository entry-point contracts.`

- [ ] **Step 6: Add the contract to the full test runner**

Append before the final success message in `windows/tests/run-tests.ps1`:

```powershell
& (Join-Path $PSScriptRoot 'repository-contract-tests.ps1')
```

- [ ] **Step 7: Run the engine-only suite and commit**

Run:

```powershell
powershell.exe -NoProfile -ExecutionPolicy Bypass -File .\windows\tests\run-tests.ps1 -EngineOnly
git add Install.ps1 Restore.ps1 windows/tests/repository-contract-tests.ps1 windows/tests/run-tests.ps1
git commit -m "feat: add root install and restore entry points"
```

Expected: the engine-only suite exits 0; the commit contains only the four listed files.

---

### Task 2: Build a whitelist-based Release ZIP and checksum

**Files:**
- Create: `windows/tests/release-package-tests.ps1`
- Create: `windows/scripts/package-release.ps1`
- Modify: `windows/tests/run-tests.ps1`

**Interfaces:**
- Consumes: repository files created in Task 1 plus the existing `windows/assets/`, `windows/scripts/`, and `windows/references/` trees.
- Produces: `codex-miku-moonlight-theme-<version>.zip` and `codex-miku-moonlight-theme-<version>.zip.sha256` under a caller-provided output directory.
- Public command: `windows/scripts/package-release.ps1 -Version <semver> [-OutputDirectory <path>]`; tests may override `-RepositoryRoot` with a disposable fixture.

- [ ] **Step 1: Write the failing release-package test**

Create `windows/tests/release-package-tests.ps1`:

```powershell
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
```

- [ ] **Step 2: Run the test and verify it fails**

Run:

```powershell
powershell.exe -NoProfile -ExecutionPolicy Bypass -File .\windows\tests\release-package-tests.ps1
```

Expected: FAIL because `windows/scripts/package-release.ps1` does not exist.

- [ ] **Step 3: Implement the whitelist packager**

Create `windows/scripts/package-release.ps1`:

```powershell
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
    if (-not (Test-Path -LiteralPath $source -PathType Leaf)) { throw "Required release file is missing: $relative" }
    $destination = Join-Path $stage $relative
    [System.IO.Directory]::CreateDirectory([System.IO.Path]::GetDirectoryName($destination)) | Out-Null
    Copy-Item -LiteralPath $source -Destination $destination -Force
  }
  foreach ($relative in $directories) {
    $source = Join-Path $repositoryRoot $relative
    if (-not (Test-Path -LiteralPath $source -PathType Container)) { throw "Required release directory is missing: $relative" }
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
```

- [ ] **Step 4: Run the test and verify it passes against the disposable fixture**

Run:

```powershell
powershell.exe -NoProfile -ExecutionPolicy Bypass -File .\windows\tests\release-package-tests.ps1
```

Expected: `PASS: release archive allowlist and checksum contracts.` The fixture proves packaging behavior independently of Task 3's final prose.

- [ ] **Step 5: Wire the package test into the full runner**

Append after `repository-contract-tests.ps1` in `windows/tests/run-tests.ps1`:

```powershell
& (Join-Path $PSScriptRoot 'release-package-tests.ps1')
```

- [ ] **Step 6: Commit the isolated packager implementation**

Run:

```powershell
git add windows/scripts/package-release.ps1 windows/tests/release-package-tests.ps1 windows/tests/run-tests.ps1
git commit -m "feat: add whitelist release packager"
```

Expected: commit succeeds with the focused package test green.

---

### Task 3: Replace stale documentation and add legal boundaries

**Files:**
- Create: `README.md`
- Create: `README.en.md`
- Delete: `README.zh-CN.md`
- Create: `LICENSE`
- Create: `NOTICE.md`
- Create: `CHANGELOG.md`
- Create: `docs/installation.md`
- Create: `docs/screenshots/.gitkeep`
- Replace: `windows/README.md`
- Replace: `windows/README.en.md`
- Modify: `windows/SKILL.md`
- Replace: `windows/CHANGELOG.md`
- Modify: `UPSTREAM.md`
- Modify: `windows/tests/repository-contract-tests.ps1`

**Interfaces:**
- Consumes: the verified product behavior and paths already implemented under `windows/`.
- Produces: Chinese-first public documentation, equivalent English documentation, MIT code licensing, an explicit third-party-asset exclusion, and files required by the Release packager.

- [ ] **Step 1: Extend repository contracts for exact public facts**

Add the following after the root wrapper checks in `windows/tests/repository-contract-tests.ps1`:

```powershell
$readmeZh = Read-RepositoryUtf8 'README.md'
$readmeEn = Read-RepositoryUtf8 'README.en.md'
$notice = Read-RepositoryUtf8 'NOTICE.md'
$license = Read-RepositoryUtf8 'LICENSE'
$installation = Read-RepositoryUtf8 'docs\installation.md'
$upstream = Read-RepositoryUtf8 'UPSTREAM.md'

foreach ($required in @(
    '26.715.3651.0',
    'Node.js 22',
    '30%',
    '5%–35%',
    '.\Install.ps1',
    '.\Restore.ps1',
    'Codex 初音未来主题',
    '%LOCALAPPDATA%\CodexMikuMoonlightTheme',
    '127.0.0.1'
  )) {
  Assert-RepositoryContract ($readmeZh.Contains($required)) "Chinese README is missing: $required"
}
foreach ($required in @(
    '26.715.3651.0',
    'Node.js 22',
    '30%',
    '5%–35%',
    '.\Install.ps1',
    '.\Restore.ps1',
    'Codex Miku Theme',
    '%LOCALAPPDATA%\CodexMikuMoonlightTheme',
    '127.0.0.1'
  )) {
  Assert-RepositoryContract ($readmeEn.Contains($required)) "English README is missing: $required"
}
foreach ($stale in @('26.715.2305.0', '默认任务背景透明度：15%', '%LOCALAPPDATA%\CodexDreamSkin', 'Codex Dream Skin - Tray')) {
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
Assert-RepositoryContract ($installation.Contains('提交 Issue')) 'Installation guide must explain issue reporting.'
Assert-RepositoryContract ($upstream.Contains('d4087e6e992b478f4626ba11e553f8bc19aea14f')) 'Pinned upstream commit changed.'
```

- [ ] **Step 2: Run contracts and verify the public-document failure**

Run:

```powershell
powershell.exe -NoProfile -ExecutionPolicy Bypass -File .\windows\tests\repository-contract-tests.ps1
```

Expected: FAIL with `Missing repository file: README.md`.

- [ ] **Step 3: Create the Chinese and English root READMEs**

Create `README.md` with these sections and exact facts:

```markdown
# Codex 初音未来·月光都市主题

[English](./README.en.md)

适用于 Windows 官方 Codex 桌面版的非官方初音未来粉丝主题。保留原生侧栏、任务内容和输入框，通过本机回环 CDP 加载月光都市背景、玻璃界面与轻量动态效果。

## 效果预览
## 功能
## 系统要求
## 从 GitHub Release 安装
## 正确启动主题
## 调整透明度与动态效果
## 更新
## 恢复与卸载
## 常见问题
## 安全说明
## 上游、许可证与素材声明
```

Populate the sections with the Global Constraints verbatim, including `26.715.3651.0`, Node.js 22+, 30%, 5%–35%, `./Install.ps1`, `./Restore.ps1`, the themed shortcut name, `%LOCALAPPDATA%\CodexMikuMoonlightTheme`, loopback-only CDP, the absence of WindowsApps/config changes, and the instruction that plain Codex startup does not load the theme.

Create `README.en.md` with the same section order and facts in English:

```markdown
# Codex Miku Moonlight Theme

[中文](./README.md)

An unofficial Hatsune Miku fan theme for the official Codex desktop app on Windows. It preserves the native sidebar, task content, and composer while loading the moonlit-city background, glass surfaces, and subtle motion through loopback-only CDP.

## Preview
## Features
## Requirements
## Install from GitHub Releases
## Start the themed Codex shortcut
## Adjust opacity and motion
## Update
## Restore and uninstall
## Troubleshooting
## Security
## Upstream, license, and artwork notice
```

Delete `README.zh-CN.md` after all current useful content has been incorporated into `README.md`.

- [ ] **Step 4: Add license, notice, changelog, and detailed installation guide**

Create `LICENSE` using the unmodified MIT permission and warranty text. The copyright line must preserve upstream authorship and identify local modifications:

```text
MIT License

Copyright (c) 2026 Codex Dream Skin Studio contributors
Copyright (c) 2026 Codex Miku Moonlight Theme contributors
```

Create `NOTICE.md` with these explicit paragraphs:

```markdown
# Notices

This repository contains software derived from Fei-Away/Codex-Dream-Skin at commit d4087e6e992b478f4626ba11e553f8bc19aea14f. See UPSTREAM.md for provenance.

This is an unofficial, non-commercial fan theme. It is not affiliated with, authorized by, sponsored by, or endorsed by OpenAI, Crypton Future Media, or any other relevant rights holder.

OpenAI, Codex, Hatsune Miku, 初音未来, associated character likenesses, names, logos, and trademarks belong to their respective rights holders.

The MIT License applies only to software source code whose contributors have the right to license it. Character artwork, third-party illustrations, trademarks, franchise assets, and other third-party materials are not covered by the MIT License. No license to those materials is granted by this repository.

Anyone redistributing this project or using it commercially must perform an independent rights review and replace or remove assets for which they do not have permission.
```

Create root `CHANGELOG.md` with `## [1.0.0] - 2026-07-18`, listing the moonlight theme, 30% task opacity, adjustable 5%–35% range, managed runtime, themed shortcut/icon, root install/restore commands, bilingual docs, tests, and automated Release packaging.

Create `docs/installation.md` with exact subsections for prerequisites, Release installation, source installation, themed startup, settings, update, restore, uninstall, paths/logs, port 9335, troubleshooting, and sanitized Issue reporting. Include the runtime and log locations returned by `Get-DreamSkinProductPaths`; never instruct users to upload tokens, `auth.json`, private conversations, or entire configuration files.

Create the empty tracked directory marker `docs/screenshots/.gitkeep`. Do not add mockups as product screenshots.

- [ ] **Step 5: Replace stale Windows documentation**

Rewrite `windows/README.md` and `windows/README.en.md` as source-maintainer guides that:

- call the product Codex Miku Moonlight Theme;
- point ordinary users to the root README and root wrappers;
- document direct source commands only for maintainers;
- use `%LOCALAPPDATA%\CodexMikuMoonlightTheme` and `package-v1`;
- state that no tray shortcut or persistence is installed;
- state that installation does not require closing an unrelated official Codex session;
- use `RemoteSigned` for installed runtime commands;
- link to `../docs/installation.md` for detailed support.

Update `windows/SKILL.md` so all product names, state paths, shortcut names, supported opacity, and no-persistence rules match the Global Constraints. Remove instructions that require a tray UI or modifications to `config.toml`.

Replace `windows/CHANGELOG.md` with a concise provenance note plus the public `1.0.0` release history; preserve the fact that the Windows implementation derives from upstream rather than presenting all upstream historical changes as local Miku releases.

Extend `UPSTREAM.md` with direct links to the upstream repository, its `macos/LICENSE`, and `macos/NOTICE.md`, while preserving the pinned commit and imported subtree.

- [ ] **Step 6: Run documentation and packaging contracts**

Run:

```powershell
powershell.exe -NoProfile -ExecutionPolicy Bypass -File .\windows\tests\repository-contract-tests.ps1
powershell.exe -NoProfile -ExecutionPolicy Bypass -File .\windows\tests\release-package-tests.ps1
rg -n "26\.715\.2305\.0|默认任务背景透明度：15%|%LOCALAPPDATA%\\CodexDreamSkin|Codex Dream Skin - Tray|桥本有菜|Arina Hashimoto" README.md README.en.md windows/README.md windows/README.en.md windows/SKILL.md docs/installation.md
```

Expected: both scripts print `PASS`; `rg` returns no matches.

- [ ] **Step 7: Commit the product documentation**

Run:

```powershell
git add README.md README.en.md README.zh-CN.md LICENSE NOTICE.md CHANGELOG.md UPSTREAM.md docs/installation.md docs/screenshots/.gitkeep windows/README.md windows/README.en.md windows/SKILL.md windows/CHANGELOG.md windows/tests/repository-contract-tests.ps1
git commit -m "docs: publish Miku theme user documentation"
```

Expected: Git records deletion of `README.zh-CN.md`, creation of the conventional root README pair, and all legal/support documents in one reviewable commit.

---

### Task 4: Add the tag-triggered GitHub Release workflow

**Files:**
- Create: `.github/workflows/release.yml`
- Modify: `windows/tests/repository-contract-tests.ps1`

**Interfaces:**
- Consumes: `windows/tests/run-tests.ps1` and `windows/scripts/package-release.ps1`.
- Produces: a GitHub Release whose tag is `v<version>` and whose two assets are the ZIP and `.zip.sha256` files.

- [ ] **Step 1: Add failing workflow contracts**

Append to `windows/tests/repository-contract-tests.ps1`:

```powershell
$workflow = Read-RepositoryUtf8 '.github\workflows\release.yml'
foreach ($required in @(
    "tags: ['v*']",
    'contents: write',
    'runs-on: windows-latest',
    'node-version: 22',
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
```

- [ ] **Step 2: Run the contract and verify it fails**

Run:

```powershell
powershell.exe -NoProfile -ExecutionPolicy Bypass -File .\windows\tests\repository-contract-tests.ps1
```

Expected: FAIL with `Missing repository file: .github\workflows\release.yml`.

- [ ] **Step 3: Implement the release workflow without a third-party release action**

Create `.github/workflows/release.yml`:

```yaml
name: Release

on:
  push:
    tags: ['v*']

permissions:
  contents: write

jobs:
  release:
    runs-on: windows-latest
    steps:
      - name: Check out tagged source
        uses: actions/checkout@v4

      - name: Use Node.js 22
        uses: actions/setup-node@v4
        with:
          node-version: 22

      - name: Run full Windows tests
        shell: powershell
        run: |
          powershell.exe -NoProfile -ExecutionPolicy Bypass -File .\windows\tests\run-tests.ps1
          powershell.exe -NoProfile -ExecutionPolicy Bypass -File .\windows\tests\miku-contract-tests.ps1
          powershell.exe -NoProfile -ExecutionPolicy Bypass -File .\windows\tests\miku-product-contract-tests.ps1

      - name: Build release archive
        shell: powershell
        run: |
          $version = '${{ github.ref_name }}'.TrimStart('v')
          powershell.exe -NoProfile -ExecutionPolicy Bypass -File .\windows\scripts\package-release.ps1 `
            -Version $version -OutputDirectory .\dist

      - name: Publish GitHub Release
        shell: powershell
        env:
          GH_TOKEN: ${{ github.token }}
        run: |
          $version = '${{ github.ref_name }}'.TrimStart('v')
          $zip = ".\dist\codex-miku-moonlight-theme-$version.zip"
          $checksum = "$zip.sha256"
          gh release create '${{ github.ref_name }}' $zip $checksum `
            --title "Codex Miku Moonlight Theme ${{ github.ref_name }}" `
            --generate-notes --verify-tag
```

- [ ] **Step 4: Run repository and full local tests**

Run:

```powershell
powershell.exe -NoProfile -ExecutionPolicy Bypass -File .\windows\tests\repository-contract-tests.ps1
powershell.exe -NoProfile -ExecutionPolicy Bypass -File .\windows\tests\run-tests.ps1
```

Expected: both commands exit 0 and include the repository, release package, and existing engine regression PASS lines.

- [ ] **Step 5: Commit the workflow**

Run:

```powershell
git add .github/workflows/release.yml windows/tests/repository-contract-tests.ps1
git commit -m "ci: publish tested GitHub releases"
```

Expected: one commit containing only the release workflow and its contract assertions.

---

### Task 5: Perform pre-publication security and archive verification

**Files:**
- Generated: `dist/codex-miku-moonlight-theme-1.0.0.zip`
- Generated: `dist/codex-miku-moonlight-theme-1.0.0.zip.sha256`
- Modify: `.gitignore`

**Interfaces:**
- Consumes: the complete source tree from Tasks 1–4.
- Produces: a clean, locally verified `v1.0.0` artifact and a repository with no generated distribution files committed.

- [ ] **Step 1: Ignore local distribution output**

Add this exact entry to `.gitignore`:

```gitignore
/dist/
```

- [ ] **Step 2: Run every source test from a fresh PowerShell process**

Run:

```powershell
powershell.exe -NoProfile -ExecutionPolicy Bypass -File .\windows\tests\run-tests.ps1
powershell.exe -NoProfile -ExecutionPolicy Bypass -File .\windows\tests\miku-contract-tests.ps1
powershell.exe -NoProfile -ExecutionPolicy Bypass -File .\windows\tests\miku-product-contract-tests.ps1
node .\windows\tests\theme-icon.test.mjs
```

Expected: all four commands exit 0 and print their final `PASS` messages.

- [ ] **Step 3: Build the exact first-release archive**

Run:

```powershell
powershell.exe -NoProfile -ExecutionPolicy Bypass -File .\windows\scripts\package-release.ps1 `
  -Version 1.0.0 -OutputDirectory .\dist
Get-FileHash -Algorithm SHA256 .\dist\codex-miku-moonlight-theme-1.0.0.zip
Get-Content .\dist\codex-miku-moonlight-theme-1.0.0.zip.sha256
```

Expected: the computed hash equals the lowercase hash at the start of the checksum file.

- [ ] **Step 4: Smoke-test the extracted user artifact**

Run:

```powershell
$smokeRoot = Join-Path ([System.IO.Path]::GetTempPath()) "codex-miku-v1-smoke-$PID-$([guid]::NewGuid().ToString('N'))"
Expand-Archive -LiteralPath .\dist\codex-miku-moonlight-theme-1.0.0.zip -DestinationPath $smokeRoot
try {
  foreach ($relative in @(
      'Install.ps1', 'Restore.ps1', 'README.md', 'README.en.md', 'LICENSE', 'NOTICE.md',
      'windows\assets\miku-moonlight-hero.png', 'windows\scripts\install-dream-skin.ps1'
    )) {
    if (-not (Test-Path -LiteralPath (Join-Path $smokeRoot $relative) -PathType Leaf)) {
      throw "Smoke archive is missing $relative"
    }
  }
  $tokens = $null; $errors = $null
  [System.Management.Automation.Language.Parser]::ParseFile(
    (Join-Path $smokeRoot 'Install.ps1'), [ref]$tokens, [ref]$errors
  ) | Out-Null
  if ($errors.Count -ne 0) { throw 'Packaged Install.ps1 failed to parse.' }
  Write-Host 'PASS: extracted v1.0.0 user archive.'
} finally {
  Remove-Item -LiteralPath $smokeRoot -Recurse -Force -ErrorAction SilentlyContinue
}
```

Expected: `PASS: extracted v1.0.0 user archive.`

- [ ] **Step 5: Scan tracked content for secrets and machine-local artifacts**

Run:

```powershell
$trackedSensitiveFiles = @(git ls-files | Where-Object {
  $_ -match '(^|/)(auth\.json|settings\.json|state\.json|[^/]*\.log|\.env)$'
})
if ($trackedSensitiveFiles.Count -ne 0) {
  throw "Sensitive runtime files are tracked: $($trackedSensitiveFiles -join ', ')"
}
$secretMatches = @(git grep -n -I -E "(ghp_[A-Za-z0-9]{20,}|github_pat_|sk-[A-Za-z0-9_-]{20,}|BEGIN (RSA|OPENSSH|EC) PRIVATE KEY)" -- . ':(exclude)docs/superpowers/*')
if ($secretMatches.Count -ne 0) { throw "Possible secret material found: $($secretMatches -join '; ')" }
$machinePathMatches = @(git grep -n -F 'C:\Users\chenhao' -- . ':(exclude)docs/superpowers/*')
if ($machinePathMatches.Count -ne 0) { throw "Machine-local path found: $($machinePathMatches -join '; ')" }
git status --short
```

Expected: no secret matches; only the intended `.gitignore` change remains, and `dist/` does not appear.

- [ ] **Step 6: Commit the distribution ignore rule**

Run:

```powershell
git add .gitignore
git commit -m "chore: ignore generated release archives"
git status --short
```

Expected: clean working tree.

---

### Task 6: Verify the installed theme from the packaged source

**Files:**
- Runtime: `%LOCALAPPDATA%\CodexMikuMoonlightTheme\package-v1`
- Settings: `%LOCALAPPDATA%\CodexMikuMoonlightTheme\runtime\settings.json`
- Shortcut: `%USERPROFILE%\Desktop\Codex 初音未来主题.lnk`

**Interfaces:**
- Consumes: extracted `v1.0.0` Release contents.
- Produces: a live installed theme with preserved user settings, 30% task opacity, and all ten verifier checks passing.

- [ ] **Step 1: Record the current theme setting before reinstall**

Run:

```powershell
$settingsPath = Join-Path $env:LOCALAPPDATA 'CodexMikuMoonlightTheme\runtime\settings.json'
$beforeSettings = if (Test-Path -LiteralPath $settingsPath) {
  [System.IO.File]::ReadAllText($settingsPath, [System.Text.UTF8Encoding]::new($false))
} else { $null }
```

Expected: `$beforeSettings` contains the current JSON or `$null`; do not print private file contents into logs.

- [ ] **Step 2: Extract and install from the generated ZIP**

Run:

```powershell
$installRoot = Join-Path ([System.IO.Path]::GetTempPath()) "codex-miku-v1-install-$PID-$([guid]::NewGuid().ToString('N'))"
Expand-Archive -LiteralPath .\dist\codex-miku-moonlight-theme-1.0.0.zip -DestinationPath $installRoot
powershell.exe -NoProfile -ExecutionPolicy Bypass -File (Join-Path $installRoot 'Install.ps1')
```

Expected: installer reports success and recreates the theme shortcuts from the packaged source.

- [ ] **Step 3: Verify settings preservation and live behavior**

Run:

```powershell
if ($null -ne $beforeSettings) {
  $afterSettings = [System.IO.File]::ReadAllText($settingsPath, [System.Text.UTF8Encoding]::new($false))
  if ($afterSettings -cne $beforeSettings) { throw 'Reinstall changed the existing theme settings.' }
}
powershell.exe -NoProfile -ExecutionPolicy RemoteSigned -File `
  "$env:LOCALAPPDATA\CodexMikuMoonlightTheme\package-v1\scripts\start-dream-skin.ps1" -PromptRestart
powershell.exe -NoProfile -ExecutionPolicy RemoteSigned -File `
  "$env:LOCALAPPDATA\CodexMikuMoonlightTheme\package-v1\scripts\verify-dream-skin.ps1"
```

Expected: the verifier reports all ten named checks as PASS, including `MikuHomeOrTaskMode`, `SettingsBridge`, `TaskOpacityRange`, and `NoAutostart`; task opacity is 30%.

- [ ] **Step 4: Remove only the temporary extracted source**

Resolve and verify `$installRoot` begins with `[System.IO.Path]::GetTempPath()` before deletion, then run:

```powershell
$resolvedInstallRoot = [System.IO.Path]::GetFullPath($installRoot)
$resolvedTemp = [System.IO.Path]::GetFullPath([System.IO.Path]::GetTempPath())
if (-not $resolvedInstallRoot.StartsWith($resolvedTemp, [System.StringComparison]::OrdinalIgnoreCase)) {
  throw "Refusing to remove a non-temporary path: $resolvedInstallRoot"
}
Remove-Item -LiteralPath $resolvedInstallRoot -Recurse -Force
```

Expected: the installed managed runtime and shortcuts remain; only the temporary extracted checkout is removed.

---

### Task 7: Create the public GitHub repository and publish `v1.0.0`

**Files:**
- Git refs: rename local `master` to `main`; create tag `v1.0.0`.
- Git remote: create `origin` for the authenticated personal account.
- External state: public GitHub repository and GitHub Release.

**Interfaces:**
- Consumes: the clean, fully verified local repository and `.github/workflows/release.yml`.
- Produces: `https://github.com/<authenticated-user>/codex-miku-moonlight-theme`, default branch `main`, and Release `v1.0.0` with two assets.

- [ ] **Step 1: Confirm authentication and exact publication target**

Run:

```powershell
gh auth status
$owner = gh api user --jq .login
if (-not $owner) { throw 'GitHub CLI did not return the authenticated personal account.' }
gh repo view "$owner/codex-miku-moonlight-theme" --json nameWithOwner 2>$null
```

Expected: authentication is active. The final command should report that the repository does not exist; if it already exists, stop and inspect it instead of overwriting or force-pushing.

- [ ] **Step 2: Re-run completion verification immediately before publication**

Run:

```powershell
git status --short
powershell.exe -NoProfile -ExecutionPolicy Bypass -File .\windows\tests\run-tests.ps1
powershell.exe -NoProfile -ExecutionPolicy Bypass -File .\windows\tests\miku-contract-tests.ps1
powershell.exe -NoProfile -ExecutionPolicy Bypass -File .\windows\tests\miku-product-contract-tests.ps1
```

Expected: clean working tree and all test commands exit 0. Do not continue if either condition fails.

- [ ] **Step 3: Rename the branch and create the public remote**

Run:

```powershell
git branch -m main
gh repo create codex-miku-moonlight-theme `
  --public `
  --source . `
  --remote origin `
  --push `
  --description "Unofficial Hatsune Miku moonlight theme for the Codex desktop app on Windows"
```

Expected: GitHub creates the repository under `$owner`, pushes `main`, and configures `origin` without modifying any other repository.

- [ ] **Step 4: Configure repository metadata and verify the default branch**

Run:

```powershell
gh repo edit "$owner/codex-miku-moonlight-theme" `
  --homepage "https://github.com/$owner/codex-miku-moonlight-theme/releases" `
  --add-topic codex `
  --add-topic windows `
  --add-topic theme `
  --add-topic hatsune-miku `
  --add-topic powershell
gh repo view "$owner/codex-miku-moonlight-theme" --json nameWithOwner,visibility,defaultBranchRef,url
```

Expected: visibility is `PUBLIC` and `defaultBranchRef.name` is `main`.

- [ ] **Step 5: Create and push the first release tag**

Run:

```powershell
git tag -a v1.0.0 -m "Codex Miku Moonlight Theme v1.0.0"
git push origin v1.0.0
```

Expected: the tag push starts the `Release` GitHub Actions workflow. Never move or recreate the published tag if the workflow fails; fix the problem and publish `v1.0.1` unless the tag has not produced any public Release and GitHub state is explicitly reviewed.

- [ ] **Step 6: Watch the workflow and verify Release assets**

Run:

```powershell
$runId = gh run list --workflow Release --limit 10 --json databaseId,headBranch `
  --jq '.[] | select(.headBranch == "v1.0.0") | .databaseId' | Select-Object -First 1
if (-not $runId) { throw 'No Release workflow run was found for v1.0.0.' }
gh run watch $runId --exit-status
gh release view v1.0.0 --json tagName,isDraft,isPrerelease,url,assets
```

Expected: workflow conclusion is success; Release is neither draft nor prerelease; assets are exactly:

```text
codex-miku-moonlight-theme-1.0.0.zip
codex-miku-moonlight-theme-1.0.0.zip.sha256
```

- [ ] **Step 7: Compare the published checksum with the published ZIP**

Run:

```powershell
$releaseCheck = Join-Path ([System.IO.Path]::GetTempPath()) "codex-miku-published-$PID-$([guid]::NewGuid().ToString('N'))"
New-Item -ItemType Directory -Path $releaseCheck | Out-Null
try {
  gh release download v1.0.0 --dir $releaseCheck
  $zip = Join-Path $releaseCheck 'codex-miku-moonlight-theme-1.0.0.zip'
  $checksum = [System.IO.File]::ReadAllText("$zip.sha256", [System.Text.UTF8Encoding]::new($false)).Trim()
  $actual = (Get-FileHash -Algorithm SHA256 -LiteralPath $zip).Hash.ToLowerInvariant()
  if ($checksum -cne "$actual  codex-miku-moonlight-theme-1.0.0.zip") {
    throw 'Published Release checksum does not match the published ZIP.'
  }
  Write-Host 'PASS: published v1.0.0 assets and checksum.'
} finally {
  Remove-Item -LiteralPath $releaseCheck -Recurse -Force -ErrorAction SilentlyContinue
}
```

Expected: `PASS: published v1.0.0 assets and checksum.`

---

## Self-review

- Spec coverage: repository structure, root wrappers, bilingual documentation, detailed installation guide, legal notice, upstream provenance, whitelist packaging, SHA-256 generation, tag automation, test failure behavior, live installation, branch rename, public repository creation, and Release verification each map to a task.
- Placeholder scan: no `TBD`, `TODO`, deferred implementation, unspecified validation, or unnamed error handling remains.
- Interface consistency: root wrappers delegate to the existing script parameters; the packager and workflow use the same version-to-filename mapping; tests and final Release checks expect the same two assets; every document uses `26.715.3651.0`, Node.js 22+, 30%, 5%–35%, and `%LOCALAPPDATA%\CodexMikuMoonlightTheme`.
- Scope: all tasks contribute to one independently testable outcome—the public `v1.0.0` product repository—so splitting into separate plans would introduce unnecessary handoff risk.
