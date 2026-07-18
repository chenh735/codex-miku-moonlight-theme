# Codex Miku Moonlight Theme

[中文](./README.md)

An unofficial Hatsune Miku fan theme for the official Codex desktop app on Windows. It preserves the native sidebar, task content, and composer while loading a moonlit-city background, glass surfaces, and subtle motion through loopback-only CDP.

![Miku moonlight city background](./windows/assets/miku-moonlight-hero.png)

## Features

- One continuous moonlight-city visual across the home and task pages.
- Task-page background opacity defaults to 30% and is adjustable from 5%–35%.
- Independent switches for stars, moon breathing, city lights, border flow, and meteors.
- A dedicated **Codex Miku Theme** desktop and Start Menu shortcut, displayed as **Codex 初音未来主题** on Windows.
- A source-independent managed runtime under `%LOCALAPPDATA%\CodexMikuMoonlightTheme`.
- One-command restoration without modifying WindowsApps, `app.asar`, the app signature, or Codex `config.toml`.

## Requirements

- Windows 10/11.
- The official `OpenAI.Codex` package installed from Microsoft Store and registered for the current user.
- Node.js 22 or newer, with `node.exe` available on `PATH`.
- Windows PowerShell 5.1 or newer.

The fully verified Codex version is `26.715.3651.0`. Other versions may work, but this project does not claim that they have been verified.

## Install from GitHub Releases

1. Open **Releases** on this repository and download `codex-miku-moonlight-theme-<version>.zip`.
2. Optionally compare it with the matching `.zip.sha256` file.
3. Extract the ZIP; do not run scripts from the archive preview window.
4. Right-click `Install.ps1` and choose **Run with PowerShell**, or run:

```powershell
powershell.exe -NoProfile -ExecutionPolicy Bypass -File .\Install.ps1
```

`Bypass` applies only to this user-initiated installation process. Installed shortcuts use `RemoteSigned`; the installer does not change permanent execution-policy settings.

## Start the themed Codex shortcut

Use **Codex 初音未来主题** from the desktop or Start Menu. Launching the official Codex icon directly opens the unmodified official appearance by design.

If Codex is already open, the themed shortcut asks before restarting it. CDP binds to `127.0.0.1`; the preferred port is `9335`, with a bounded automatic fallback when that port is busy.

## Adjust opacity and motion

The in-app theme panel adjusts task opacity from 5%–35%; the default is 30%. Stars, moon breathing, city lights, the animated border, and meteors can be toggled independently or paused together.

Settings are stored only in `%LOCALAPPDATA%\CodexMikuMoonlightTheme\runtime\settings.json` and do not modify Codex configuration.

## Update

Download and extract a newer Release, then run `.\Install.ps1` again. The installer atomically replaces the managed package and refreshes shortcuts while preserving theme settings.

After a Codex update, reinstall first and then use the themed shortcut. The launcher discovers the currently registered Store package instead of trusting an old WindowsApps path.

## Restore and uninstall

Restore the official interface and close the themed debugging session:

```powershell
powershell.exe -NoProfile -ExecutionPolicy Bypass -File .\Restore.ps1 -PromptRestart
```

Also remove themed shortcuts and the managed theme directory:

```powershell
powershell.exe -NoProfile -ExecutionPolicy Bypass -File .\Restore.ps1 -Uninstall -PromptRestart
```

Restore never deletes Codex tasks, projects, authentication, or other user data.

## Troubleshooting

- **Home is themed but the task page looks nearly white:** increase task opacity in the theme settings; 30% is the default.
- **The official Codex icon has no theme:** use the dedicated `Codex 初音未来主题` shortcut.
- **Node.js is missing:** run `node --version` and install Node.js 22+ if required.
- **A Codex update broke the theme:** rerun `.\Install.ps1`.
- **Port or injection failure:** inspect `%LOCALAPPDATA%\CodexMikuMoonlightTheme\runtime\logs` and follow [the detailed installation guide](./docs/installation.md).

## Security

- CDP listens only on `127.0.0.1`; it is not exposed to the LAN.
- CDP has no separate authentication against other processes running as the same Windows user. Do not run untrusted local software while the theme is active.
- The project does not upload conversations, tasks, or workspace data to third-party servers.
- Run `.\Restore.ps1` when you no longer need the themed debugging session.
- Scripts accept only the registered Microsoft Store Codex package and verify package, path, Browser ID, and session state before stopping processes.

## Upstream, license, and artwork notice

This project derives from the Windows implementation in [Fei-Away/Codex-Dream-Skin](https://github.com/Fei-Away/Codex-Dream-Skin); see [UPSTREAM.md](./UPSTREAM.md) for the pinned source. Software code is distributed under the [MIT License](./LICENSE).

Hatsune Miku names, character likenesses, related trademarks, and third-party artwork are not included in the MIT software grant. This is an unofficial, non-commercial fan theme with no affiliation, authorization, or endorsement from OpenAI, Crypton Future Media, or other rights holders. Read [NOTICE.md](./NOTICE.md) and perform an independent rights review before redistribution or commercial use.
