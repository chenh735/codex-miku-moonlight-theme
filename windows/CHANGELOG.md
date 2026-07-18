# Windows implementation changelog

The Windows implementation was imported from Fei-Away/Codex-Dream-Skin at the commit recorded in `../UPSTREAM.md`, then adapted into the standalone Miku product below. Upstream history remains available in the source repository and is not presented as local Miku release history.

## 1.0.0 — 2026-07-18

- Shipped the approved `miku-moonlight-city-v1` theme for home and task routes.
- Added 30% default task opacity with a 5%–35% persisted setting.
- Added moonlight, stars, city lights, border flow, meteor controls, and reduced-motion behavior.
- Moved the managed package and runtime under `%LOCALAPPDATA%\CodexMikuMoonlightTheme`.
- Added source-independent launch and restore shortcuts with the custom Miku music-mark icon.
- Removed product-level tray, autostart, scheduled-task, service, Run-key, and `config.toml` behavior.
- Added Appx identity, loopback CDP, renderer, artwork, settings, product, and packaging regression tests.
