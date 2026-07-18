# Changelog

All notable changes to this product are documented here. Versions follow Semantic Versioning.

## [1.0.2] - 2026-07-18

- Replaced the unreliable draggable opacity slider with `－ [number] ＋` controls.
- Added direct 5–100 entry, Enter/focus-change commit, Escape restore, integer clamping, and accessible decrement/increment buttons.
- Preserved existing opacity and effect settings across the update.

## [1.0.1] - 2026-07-18

- Moved the `✦` settings trigger clear of the native Windows caption controls, enlarged its hit target, and explicitly excluded it from draggable regions.
- Extended persisted task opacity adjustment from 5%–35% to 5%–100% while retaining the 30% default.
- Added responsive trigger placement for narrow windows and documented the readability trade-off at 100%.

## [1.0.0] - 2026-07-18

- Added the initial public Codex Miku Moonlight Theme for Windows.
- Applied the moonlight-city artwork to home and task pages.
- Set task opacity to 30% by default with a 5%–35% adjustable range.
- Added independent motion controls and reduced-motion support.
- Added a managed runtime and the `Codex 初音未来主题` shortcut with a custom Miku icon.
- Added stable root `Install.ps1` and `Restore.ps1` commands.
- Added Chinese and English user documentation, regression tests, whitelist packaging, and automated GitHub Releases.
