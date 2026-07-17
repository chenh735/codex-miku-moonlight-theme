$ErrorActionPreference = 'Stop'
Set-StrictMode -Version Latest

$windowsRoot = Split-Path -Parent $PSScriptRoot
$scriptsRoot = Join-Path $windowsRoot 'scripts'
$shippingScripts = Get-ChildItem -LiteralPath $scriptsRoot -File |
  Where-Object { $_.Extension -in @('.ps1', '.mjs') }

function Assert-Contract {
  param(
    [Parameter(Mandatory = $true)][bool]$Condition,
    [Parameter(Mandatory = $true)][string]$Message
  )

  if (-not $Condition) { throw $Message }
}

function Read-Utf8File {
  param([Parameter(Mandatory = $true)][string]$Path)
  return [System.IO.File]::ReadAllText($Path, [System.Text.UTF8Encoding]::new($false))
}

$commonPath = Join-Path $scriptsRoot 'common-windows.ps1'
$common = Read-Utf8File -Path $commonPath
$installer = Read-Utf8File -Path (Join-Path $scriptsRoot 'install-dream-skin.ps1')
$restore = Read-Utf8File -Path (Join-Path $scriptsRoot 'restore-dream-skin.ps1')

Assert-Contract ($common.Contains("'CodexMikuMoonlightTheme'")) `
  'The shared Windows helpers must define the CodexMikuMoonlightTheme state root.'
Assert-Contract ($common.Contains("'package-v1'")) `
  'The shared Windows helpers must define package-v1 as the installed package directory.'
Assert-Contract ($common.Contains("'runtime'")) `
  'The shared Windows helpers must define the runtime directory.'
Assert-Contract ($common.Contains("'settings.json'")) `
  'The shared Windows helpers must define the runtime settings path.'
Assert-Contract ($common.Contains("'scripts\miku-settings.mjs'")) `
  'The managed runtime must require the Miku settings module.'

foreach ($file in $shippingScripts) {
  $content = Read-Utf8File -Path $file.FullName
  Assert-Contract (-not [regex]::IsMatch(
      $content,
      "Join-Path[\s\S]{0,80}LOCALAPPDATA[\s\S]{0,80}'CodexDreamSkin'",
      [System.Text.RegularExpressions.RegexOptions]::IgnoreCase
    )) "Shipping script still uses the legacy CodexDreamSkin state root: $($file.Name)"
}

Assert-Contract ($installer.Contains("'Codex 初音未来主题.lnk'")) `
  'Installer must create the approved Codex 初音未来主题 shortcut.'
Assert-Contract ($installer.Contains("'还原 Codex 官方界面.lnk'")) `
  'Installer must create the approved restore shortcut.'
Assert-Contract ($restore.Contains("'Codex 初音未来主题.lnk'")) `
  'Restore must remove the approved launcher shortcut during uninstall.'
Assert-Contract ($restore.Contains("'还原 Codex 官方界面.lnk'")) `
  'Restore must remove the approved restore shortcut during uninstall.'
Assert-Contract (-not $installer.Contains('Codex Dream Skin - Tray.lnk')) `
  'Installer must not create a tray shortcut.'
Assert-Contract (-not $installer.Contains('Start-Process -FilePath $powershell')) `
  'Installer must not launch a persistent tray process.'
Assert-Contract (-not $installer.Contains('Close Codex before installing')) `
  'Package-only installation must not require closing a running official Codex session.'

foreach ($entryPoint in @(
    'install-dream-skin.ps1',
    'start-dream-skin.ps1',
    'restore-dream-skin.ps1',
    'verify-dream-skin.ps1'
  )) {
  $content = Read-Utf8File -Path (Join-Path $scriptsRoot $entryPoint)
  Assert-Contract (-not $content.Contains('.codex\config.toml')) `
    "$entryPoint must not read or write Codex config.toml."
  Assert-Contract (-not $content.Contains('Install-DreamSkinBaseTheme')) `
    "$entryPoint must not install a base theme through config.toml."
  Assert-Contract (-not $content.Contains('Restore-DreamSkinBaseTheme')) `
    "$entryPoint must not restore config.toml as part of theme lifecycle."
}

$forbiddenPersistence = @(
  'schtasks',
  'New-Service',
  'Set-Service',
  'Register-ScheduledTask'
)
foreach ($file in $shippingScripts) {
  $content = Read-Utf8File -Path $file.FullName
  foreach ($pattern in $forbiddenPersistence) {
    Assert-Contract (-not [regex]::IsMatch(
        $content,
        $pattern,
        [System.Text.RegularExpressions.RegexOptions]::IgnoreCase
      )) "Forbidden persistence mechanism '$pattern' found in $($file.Name)."
  }
}
foreach ($file in $shippingScripts) {
  $content = Read-Utf8File -Path $file.FullName
  Assert-Contract (-not [regex]::IsMatch(
      $content,
      '(?:New|Set)-ItemProperty[\s\S]{0,160}CurrentVersion\\Run',
      [System.Text.RegularExpressions.RegexOptions]::IgnoreCase
    )) "Shipping script writes a Run-registry persistence value: $($file.Name)"
}

$start = Read-Utf8File -Path (Join-Path $scriptsRoot 'start-dream-skin.ps1')
Assert-Contract ($start.Contains('--remote-debugging-address=127.0.0.1')) `
  'The launcher must bind CDP to 127.0.0.1.'
Assert-Contract ($start.Contains("'--settings-file'")) `
  'The launcher must pass the theme-local settings file to the injector.'
Assert-Contract (-not $start.Contains('--remote-debugging-address=0.0.0.0')) `
  'The launcher must never bind CDP to 0.0.0.0.'

$verify = Read-Utf8File -Path (Join-Path $scriptsRoot 'verify-dream-skin.ps1')
foreach ($checkName in @(
    'OfficialPackage',
    'LoopbackOnly',
    'ProcessIdentity',
    'BrowserId',
    'RendererTarget',
    'ThemeRootClass',
    'MikuHomeOrTaskMode',
    'SettingsBridge',
    'TaskOpacityRange',
    'NoAutostart'
  )) {
  Assert-Contract ($verify.Contains($checkName)) "Verifier is missing named check: $checkName"
}

$qa = Read-Utf8File -Path (Join-Path $windowsRoot 'references\qa-inventory.md')
$runtimeNotes = Read-Utf8File -Path (Join-Path $windowsRoot 'references\runtime-notes.md')
Assert-Contract ($qa.Contains('初音未来·月光都市')) 'QA inventory must describe the approved Miku theme.'
Assert-Contract ($qa.Contains('5%–35%')) 'QA inventory must cover the full opacity range.'
Assert-Contract ($runtimeNotes.Contains('%LOCALAPPDATA%\CodexMikuMoonlightTheme\runtime\state.json')) `
  'Runtime notes must document the Miku state path.'
Assert-Contract (-not $qa.Contains('Arina Hashimoto')) 'QA inventory still describes the old bundled theme.'
Assert-Contract (-not $runtimeNotes.Contains('%LOCALAPPDATA%\CodexDreamSkin')) `
  'Runtime notes still document the legacy state root.'
Assert-Contract ($runtimeNotes.Contains('does not read or write Codex config.toml')) `
  'Runtime notes must document config.toml non-interference.'

Write-Host 'PASS: Miku product namespace, shortcut, persistence, and loopback contracts.'
