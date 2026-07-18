# Windows source and maintainer guide

End users should start with the root [README.en.md](../README.en.md) and use the root `Install.ps1` and `Restore.ps1` entry points.

This directory contains the Windows implementation of Codex Miku Moonlight Theme: theme assets, the CDP injector, PowerShell lifecycle scripts, maintainer references, and regression tests.

## Install directly from source

```powershell
powershell.exe -NoProfile -ExecutionPolicy Bypass -File .\scripts\install-dream-skin.ps1
```

The installer copies the managed package to `%LOCALAPPDATA%\CodexMikuMoonlightTheme\package-v1`; settings and state live under `%LOCALAPPDATA%\CodexMikuMoonlightTheme\runtime`. It creates only the `Codex 初音未来主题` and official-restore entries. It does not install a tray shortcut, service, scheduled task, Run-registry value, or autostart entry.

Installation does not modify WindowsApps, `app.asar`, the app signature, API/model settings, or Codex `config.toml`, and copying the runtime does not require an unrelated official Codex session to be closed.

## Start and restore

```powershell
powershell.exe -NoProfile -ExecutionPolicy RemoteSigned -File `
  "$env:LOCALAPPDATA\CodexMikuMoonlightTheme\package-v1\scripts\start-dream-skin.ps1" -PromptRestart

powershell.exe -NoProfile -ExecutionPolicy RemoteSigned -File `
  "$env:LOCALAPPDATA\CodexMikuMoonlightTheme\package-v1\scripts\restore-dream-skin.ps1" -RestoreBaseTheme
```

## Tests

```powershell
powershell.exe -NoProfile -ExecutionPolicy Bypass -File .\tests\run-tests.ps1
powershell.exe -NoProfile -ExecutionPolicy Bypass -File .\tests\miku-contract-tests.ps1
powershell.exe -NoProfile -ExecutionPolicy Bypass -File .\tests\miku-product-contract-tests.ps1
```

See the [detailed installation guide](../docs/installation.md) for setup, paths, logs, and troubleshooting.
