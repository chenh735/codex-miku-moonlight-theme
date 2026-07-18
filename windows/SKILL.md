---
name: codex-miku-moonlight-theme
description: Install, launch, verify, update, or safely restore the Miku Moonlight theme for the official Windows Codex desktop app.
---

# Codex Miku Moonlight Theme

Apply the approved Miku moonlight-city renderer theme through loopback-only Chromium DevTools Protocol while launching the registered Microsoft Store Codex package.

## Workflow

1. Require Node.js 22+ and the official registered `OpenAI.Codex` Store package.
2. Install from the repository root with `Install.ps1`; the stable implementation lives in `scripts/install-dream-skin.ps1`.
3. Launch through “Codex 初音未来主题”. A plain official Codex launch intentionally has no theme.
4. Verify both the home page and a normal task with `scripts/verify-dream-skin.ps1`.
5. Restore with the root `Restore.ps1` or `scripts/restore-dream-skin.ps1 -RestoreBaseTheme`.

## Product contract

- Managed package: `%LOCALAPPDATA%\CodexMikuMoonlightTheme\package-v1`.
- Runtime settings/state/logs: `%LOCALAPPDATA%\CodexMikuMoonlightTheme\runtime`.
- Default task opacity: 30%; allowed range: 5%–100%.
- Approved shortcuts: “Codex 初音未来主题” and “还原 Codex 官方界面”.
- No tray shortcut, service, scheduled task, Run key, Startup entry, or other persistence.
- No WindowsApps ownership change, `app.asar` edit, signature change, API/model setting change, or Codex `config.toml` read/write.
- CDP binds to `127.0.0.1`; explicit non-loopback endpoints are rejected.
- The official shortcut, user tasks, projects, plugins, pets, authentication, and workspace data remain unchanged.

## Guardrails

- Accept only a registered, Store-signed, non-development Codex package.
- Revalidate package identity, executable path, Browser ID, port ownership, and injector identity before process control.
- Treat the loopback debugging port as sensitive because CDP has no same-user process authentication.
- Keep decorative layers `pointer-events: none`; native navigation and composer controls remain interactive.
- Preserve the approved `miku-moonlight-hero.png` bytes and `theme.json` contract.
- Reject images above 16 MB, 16384 px on either dimension, or 50 MP, and reject managed-path links/junctions.
- Install staged runtime files atomically and use `RemoteSigned` for daily shortcuts.
- Do not change persistent PowerShell execution policy or bypass Group Policy.
- Preserve settings across reinstall; uninstall only theme-owned paths and shortcuts.

## Checks

```powershell
powershell.exe -NoProfile -ExecutionPolicy Bypass -File .\tests\run-tests.ps1
powershell.exe -NoProfile -ExecutionPolicy Bypass -File .\tests\miku-contract-tests.ps1
powershell.exe -NoProfile -ExecutionPolicy Bypass -File .\tests\miku-product-contract-tests.ps1
```

Use `references/qa-inventory.md` for visual signoff and `references/runtime-notes.md` for runtime diagnostics.
