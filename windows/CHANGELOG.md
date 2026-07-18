# Windows implementation changelog

The Windows implementation was imported from Fei-Away/Codex-Dream-Skin at the commit recorded in `../UPSTREAM.md`, then adapted into the standalone Miku product below. Upstream history remains available in the source repository and is not presented as local Miku release history.

## 1.0.2 — 2026-07-18

- Removed the native draggable opacity range and its range-specific CSS.
- Added a direct 5–100 numeric input with accessible decrement and increment buttons.
- Added Enter, Escape, focus-change, clamping, persistence, and reinjection regression coverage.

## 1.0.1 — 2026-07-18

- Moved and enlarged the settings trigger so native Windows caption controls no longer intercept physical clicks.
- Marked the trigger as an explicit interactive no-drag region and added narrow-window placement.
- Extended persisted task opacity to the full 5%–100% range while preserving the 30% default.

## 1.0.0 — 2026-07-18

- Shipped the approved `miku-moonlight-city-v1` theme for home and task routes.
- Added 30% default task opacity with a 5%–35% persisted setting.
- Added moonlight, stars, city lights, border flow, meteor controls, and reduced-motion behavior.
- Moved the managed package and runtime under `%LOCALAPPDATA%\CodexMikuMoonlightTheme`.
- Added source-independent launch and restore shortcuts with the custom Miku music-mark icon.
- Removed product-level tray, autostart, scheduled-task, service, Run-key, and `config.toml` behavior.
- Added Appx identity, loopback CDP, renderer, artwork, settings, product, and packaging regression tests.
