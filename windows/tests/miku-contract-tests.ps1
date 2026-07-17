$ErrorActionPreference = 'Stop'
Set-StrictMode -Version Latest

$windowsRoot = Split-Path -Parent $PSScriptRoot
$assetPath = Join-Path $windowsRoot 'assets\miku-moonlight-hero.png'
$themePath = Join-Path $windowsRoot 'assets\theme.json'
$metadataScript = Join-Path $windowsRoot 'scripts\image-metadata.mjs'

function Assert-MikuContract {
  param(
    [Parameter(Mandatory = $true)][bool]$Condition,
    [Parameter(Mandatory = $true)][string]$Message
  )
  if (-not $Condition) { throw $Message }
}

Assert-MikuContract (Test-Path -LiteralPath $assetPath -PathType Leaf) `
  'The approved Miku moonlight hero asset is missing.'

$asset = Get-Item -LiteralPath $assetPath
Assert-MikuContract ($asset.Length -le 16MB) 'The approved hero exceeds the 16 MB safety limit.'
$hash = (Get-FileHash -LiteralPath $assetPath -Algorithm SHA256).Hash
Assert-MikuContract ($hash -ceq '7FE9F7AF8D0BB394F267B936262204E6020D40B6196B824ED500787A8FF2D7EE') `
  'The packaged hero is not byte-identical to the user-approved artwork.'

$metadataJson = & node $metadataScript --check $assetPath
Assert-MikuContract ($LASTEXITCODE -eq 0) 'The approved hero failed strict image metadata validation.'
$metadata = $metadataJson | ConvertFrom-Json
Assert-MikuContract ($metadata.width -le 16384 -and $metadata.height -le 16384) `
  'The approved hero exceeds the 16384 px dimension limit.'
Assert-MikuContract (($metadata.width * $metadata.height) -le 50000000) `
  'The approved hero exceeds the 50 MP safety limit.'
Assert-MikuContract ($metadata.ratio -ge 1.70 -and $metadata.ratio -le 1.85) `
  'The approved hero must remain a landscape 16:9-class composition.'

$theme = [System.IO.File]::ReadAllText($themePath, [System.Text.UTF8Encoding]::new($false)) |
  ConvertFrom-Json
Assert-MikuContract ($theme.schemaVersion -eq 1) 'Theme schemaVersion must remain 1.'
Assert-MikuContract ($theme.id -ceq 'miku-moonlight-city-v1') 'Theme id is not the approved Miku id.'
Assert-MikuContract ($theme.name -ceq '初音未来·月光都市') 'Theme name is not the approved title.'
Assert-MikuContract ($theme.image -ceq 'miku-moonlight-hero.png') 'Theme must reference the approved hero.'
Assert-MikuContract ($theme.art.focusX -eq 0.76 -and $theme.art.focusY -eq 0.44) `
  'Theme focus coordinates do not preserve Miku on the right.'
Assert-MikuContract ($theme.art.safeArea -ceq 'left' -and $theme.art.taskMode -ceq 'ambient') `
  'Theme art safe-area or task mode is incorrect.'
Assert-MikuContract ($theme.palette.accent -ceq '#39E6DF') 'Theme cyan accent is incorrect.'
Assert-MikuContract ($theme.palette.violet -ceq '#7C5CFF') 'Theme violet accent is incorrect.'
Assert-MikuContract ($theme.palette.pink -ceq '#FF78C6') 'Theme pink accent is incorrect.'

$cssPath = Join-Path $windowsRoot 'assets\dream-skin.css'
$css = [System.IO.File]::ReadAllText($cssPath, [System.Text.UTF8Encoding]::new($false))
foreach ($requiredCss in @(
    'html.codex-miku-theme',
    '#codex-miku-theme-settings',
    '.codex-miku-hero',
    '.codex-miku-action-grid',
    '.codex-miku-action-card',
    '.codex-miku-stars',
    '.codex-miku-moon-glow',
    '.codex-miku-city-lights',
    '.codex-miku-border-flow',
    '.codex-miku-meteor',
    '--miku-task-opacity: 0.30',
    '@keyframes miku-star-twinkle',
    '@keyframes miku-moon-breathe',
    '@keyframes miku-city-pulse',
    '@keyframes miku-border-flow',
    '@keyframes miku-meteor-pass',
    '@media (prefers-reduced-motion: reduce)',
    '@media (max-width: 900px)',
    '@media (max-width: 620px)'
  )) {
  Assert-MikuContract ($css.Contains($requiredCss)) "Miku CSS is missing: $requiredCss"
}

foreach ($decorativeSelector in @(
    '.codex-miku-stars',
    '.codex-miku-moon-glow',
    '.codex-miku-city-lights',
    '.codex-miku-border-flow',
    '.codex-miku-meteor'
  )) {
  $pattern = [regex]::Escape($decorativeSelector) + '[^{]*\{[^}]*pointer-events\s*:\s*none'
  Assert-MikuContract ([regex]::IsMatch(
      $css,
      $pattern,
      [System.Text.RegularExpressions.RegexOptions]::IgnoreCase
    )) "Decorative layer must ignore pointer input: $decorativeSelector"
}
Assert-MikuContract ([regex]::IsMatch(
    $css,
    '#codex-miku-theme-settings[^{]*\{[^}]*pointer-events\s*:\s*auto',
    [System.Text.RegularExpressions.RegexOptions]::IgnoreCase
  )) 'The Miku settings panel must remain interactive.'
Assert-MikuContract ($css.Contains('animation: miku-meteor-pass 24s')) `
  'Meteor animation must remain occasional rather than continuous.'
Assert-MikuContract ($css.Contains('html.codex-miku-theme.codex-miku-task')) `
  'Task-mode ambient styling must be namespaced and distinct from home.'
Assert-MikuContract ($css.Contains('var(--miku-task-surface-opacity)')) `
  'Task conversation glass must follow the adjustable Miku opacity setting.'
Assert-MikuContract ([regex]::IsMatch(
    $css,
    'html\.codex-dream-skin\.codex-miku-theme\.codex-miku-task[^\{]*main\.main-surface[^\{]*\{[^}]*background\s*:\s*transparent\s*!important',
    [System.Text.RegularExpressions.RegexOptions]::IgnoreCase
  )) 'Task main surface must remain transparent so the conversation glass is not double-stacked.'

$rendererPath = Join-Path $windowsRoot 'assets\renderer-inject.js'
$renderer = [System.IO.File]::ReadAllText($rendererPath, [System.Text.UTF8Encoding]::new($false))
foreach ($requiredRenderer in @(
    'findNativeComposer',
    'setComposerPrompt',
    'mountMikuHome',
    'mountMikuSettings',
    'applyMikuSettings',
    'syncMikuLayout',
    '--miku-task-surface-opacity',
    'window.__CODEX_MIKU_THEME_SETTINGS__',
    'data-codex-miku-owned',
    'min = "5"',
    'max = "35"',
    'step = "1"',
    '探索并理解代码',
    '构建新功能',
    '审查代码改动',
    '诊断并修复问题',
    '帮我理解并梳理这个代码库：先说明整体结构、关键模块与运行方式，再列出最值得优先处理的三个问题。',
    '根据我的目标构建一个新功能：先澄清必要约束，给出实现方案，再编码、测试并总结改动。',
    '审查当前改动：重点检查正确性、边界条件、安全性和测试覆盖，并按优先级给出可执行建议。',
    '诊断并修复当前问题：先复现并定位根因，再进行最小修改，运行相关测试并说明验证结果。'
  )) {
  Assert-MikuContract ($renderer.Contains($requiredRenderer)) "Miku renderer is missing: $requiredRenderer"
}
foreach ($forbiddenSubmitPath in @('.click()', 'requestSubmit(', 'KeyboardEvent(', 'key: "Enter"')) {
  Assert-MikuContract (-not $renderer.Contains($forbiddenSubmitPath)) `
    "Miku prompt cards must not contain a submit path: $forbiddenSubmitPath"
}

$injectorPath = Join-Path $windowsRoot 'scripts\injector.mjs'
$injectorSource = [System.IO.File]::ReadAllText($injectorPath, [System.Text.UTF8Encoding]::new($false))
foreach ($requiredBridge in @(
    'from "./miku-settings.mjs"',
    'readSettings',
    'sanitizeSettings',
    'resolveSettingsPath',
    'writeSettingsAtomic',
    '__DREAM_MIKU_SETTINGS_JSON__',
    'window.__CODEX_MIKU_THEME_SETTINGS__ ?? null',
    'MIKU_SETTINGS_DEBOUNCE_MS = 300',
    '--settings-file',
    'settingsRevision'
  )) {
  Assert-MikuContract ($injectorSource.Contains($requiredBridge)) `
    "Injector settings bridge is missing: $requiredBridge"
}
Assert-MikuContract (-not $injectorSource.Contains('Runtime.addBinding')) `
  'The settings bridge must not expose a CDP runtime binding.'
Assert-MikuContract ($renderer.Contains('__DREAM_MIKU_SETTINGS_JSON__')) `
  'Renderer template must receive sanitized initial settings as a fourth argument.'
foreach ($requiredProbeField in @(
    'mikuTheme',
    'mikuMode',
    'settingsBridge',
    'taskOpacity',
    'taskOpacityInRange'
  )) {
  Assert-MikuContract ($injectorSource.Contains($requiredProbeField)) `
    "Live verifier is missing Miku probe field: $requiredProbeField"
}

Write-Host 'PASS: approved Miku artwork and theme metadata contracts.'
