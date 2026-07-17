[CmdletBinding()]
param(
  [int]$Port = 9335,
  [string]$ScreenshotPath
)

$ErrorActionPreference = 'Stop'
$PortExplicit = $PSBoundParameters.ContainsKey('Port')
$injector = Join-Path $PSScriptRoot 'injector.mjs'
. (Join-Path $PSScriptRoot 'common-windows.ps1')

function Test-MikuNoAutostart {
  $namePattern = 'CodexMikuMoonlightTheme|Codex 初音未来主题|初音未来·月光都市'
  foreach ($runKey in @(
      'HKCU:\Software\Microsoft\Windows\CurrentVersion\Run',
      'HKCU:\Software\Microsoft\Windows\CurrentVersion\RunOnce'
    )) {
    $item = Get-ItemProperty -LiteralPath $runKey -ErrorAction SilentlyContinue
    if ($item -and @($item.PSObject.Properties | Where-Object {
          $_.Name -match $namePattern -or "$( $_.Value )" -match $namePattern
        }).Count -gt 0) { return $false }
  }

  foreach ($startup in @(
      [Environment]::GetFolderPath('Startup'),
      [Environment]::GetFolderPath('CommonStartup')
    )) {
    if ($startup -and (Test-Path -LiteralPath $startup) -and
      @(Get-ChildItem -LiteralPath $startup -Force -ErrorAction SilentlyContinue | Where-Object {
          $_.Name -match $namePattern
        }).Count -gt 0) { return $false }
  }

  if (Get-Command Get-ScheduledTask -ErrorAction SilentlyContinue) {
    if (@(Get-ScheduledTask -ErrorAction SilentlyContinue | Where-Object {
          $_.TaskName -match $namePattern -or $_.TaskPath -match $namePattern
        }).Count -gt 0) { return $false }
  }
  if (@(Get-Service -ErrorAction SilentlyContinue | Where-Object {
        $_.Name -match $namePattern -or $_.DisplayName -match $namePattern
      }).Count -gt 0) { return $false }
  return $true
}

function Write-MikuVerificationCheck {
  param(
    [Parameter(Mandatory = $true)][string]$Name,
    [Parameter(Mandatory = $true)][bool]$Passed,
    [string]$Detail = ''
  )
  $status = if ($Passed) { 'PASS' } else { 'FAIL' }
  $suffix = if ($Detail) { " - $Detail" } else { '' }
  Write-Host "[$status] $Name$suffix"
}

$checkNames = @(
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
)
$checks = @{}
foreach ($name in $checkNames) { $checks[$name] = $false }
$details = @{}

$operationLock = Enter-DreamSkinOperationLock
try {
  $product = Get-DreamSkinProductPaths
  $StatePath = $product.State
  $state = Read-DreamSkinState -Path $StatePath
  if (-not $PortExplicit -and $null -ne $state -and $state.port) { $Port = [int]$state.port }
  Assert-DreamSkinPort -Port $Port

  $node = Get-DreamSkinNodeRuntime
  $currentCodex = Get-DreamSkinCodexInstall
  $checks.OfficialPackage = $null -ne $currentCodex
  $details.OfficialPackage = "$($currentCodex.PackageFullName)"
  $codex = $currentCodex
  $cdpIdentity = Get-DreamSkinVerifiedCdpIdentity -Port $Port -Codex $codex
  if ($null -eq $cdpIdentity -and $null -ne $state) {
    $savedCodex = Get-DreamSkinCodexInstallFromState -State $state
    if ($null -ne $savedCodex -and
      -not (Test-DreamSkinPathEqual -Left $savedCodex.Executable -Right $currentCodex.Executable)) {
      $savedIdentity = Get-DreamSkinVerifiedCdpIdentity -Port $Port -Codex $savedCodex
      if ($null -ne $savedIdentity) {
        $codex = $savedCodex
        $cdpIdentity = $savedIdentity
      }
    }
  }

  $checks.LoopbackOnly = Test-DreamSkinCodexPortOwner -Port $Port -Codex $codex
  $checks.ProcessIdentity = $null -ne $cdpIdentity
  if ($null -eq $cdpIdentity) {
    throw "No verified Codex CDP endpoint is active on loopback port $Port."
  }
  $details.LoopbackOnly = "127.0.0.1/::1 port $Port"
  $details.ProcessIdentity = $codex.Executable

  $checks.BrowserId = $null -eq $state -or -not $state.browserId -or
    "$($state.browserId)" -ceq $cdpIdentity.BrowserId
  $details.BrowserId = $cdpIdentity.BrowserId
  if (-not $checks.BrowserId) {
    throw 'The active CDP browser does not match the saved theme session; state was preserved.'
  }

  $arguments = @(
    $injector, '--verify', '--port', "$Port", '--browser-id', $cdpIdentity.BrowserId,
    '--timeout-ms', '30000', '--settings-file', $product.Settings
  )
  if ($ScreenshotPath) { $arguments += @('--screenshot', $ScreenshotPath) }
  $probe = Invoke-DreamSkinNative -FilePath $node.Path -ArgumentList $arguments
  if ($probe.ExitCode -ne 0) {
    throw "Renderer verification failed: $($probe.Output -join ' ')"
  }
  $report = ($probe.Output -join "`n") | ConvertFrom-Json
  $targets = @($report.targets)
  $results = @($targets | ForEach-Object { $_.result } | Where-Object { $null -ne $_ })
  $checks.RendererTarget = $results.Count -gt 0
  $checks.ThemeRootClass = @($results | Where-Object { $_.mikuTheme }).Count -gt 0
  $checks.MikuHomeOrTaskMode = @($results | Where-Object { $_.mikuMode -in @('home', 'task') }).Count -gt 0
  $checks.SettingsBridge = @($results | Where-Object { $_.settingsBridge }).Count -gt 0
  $checks.TaskOpacityRange = @($results | Where-Object { $_.taskOpacityInRange }).Count -gt 0
  if ($results.Count -gt 0) {
    $details.RendererTarget = "$($results.Count) verified target(s)"
    $details.ThemeRootClass = "$($results[0].mikuMode)"
    $details.MikuHomeOrTaskMode = "$($results[0].mikuMode)"
    $details.SettingsBridge = "revision available"
    $details.TaskOpacityRange = "$([math]::Round([double]$results[0].taskOpacity * 100))%"
  }
  $checks.NoAutostart = Test-MikuNoAutostart
} catch {
  $details.Error = $_.Exception.Message
  Write-Warning $_.Exception.Message
} finally {
  Exit-DreamSkinOperationLock -Mutex $operationLock
}

foreach ($name in $checkNames) {
  Write-MikuVerificationCheck -Name $name -Passed ([bool]$checks[$name]) -Detail "$($details[$name])"
}
if ($details.Error) { Write-Host "[ERROR] $($details.Error)" }

if (@($checkNames | Where-Object { -not $checks[$_] }).Count -gt 0) { exit 2 }
exit 0
