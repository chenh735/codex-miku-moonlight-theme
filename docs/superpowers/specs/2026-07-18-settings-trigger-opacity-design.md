# Miku Settings Trigger and 100% Opacity Design

Date: 2026-07-18
Status: Approved by user delegation (implement without further questions)

## Goal

Make the Miku settings trigger physically clickable in the Codex Windows title-bar layout and extend task background opacity from 5%–35% to 5%–100%, while retaining the 30% default and all existing user settings.

## Root cause evidence

The live renderer contains the settings button, `document.elementFromPoint()` resolves the button at its center, `pointer-events` is `auto`, and a programmatic click toggles the panel. The live bounding box is 36×36 at `top: 14px; right: 18px`. That location overlaps the Windows caption-control area at the top-right edge, so native title-bar controls can intercept physical input before Chromium receives it. The current button also lacks an explicit no-drag declaration and pointer cursor.

## Interaction design

For normal-width windows, keep the trigger in the top title bar but move it left of the native minimize, maximize, and close controls:

- `top: 10px`
- `right: 154px`
- `width: 44px`
- `height: 44px`
- `pointer-events: auto`
- `-webkit-app-region: no-drag`
- `cursor: pointer`
- `touch-action: manipulation`

The 154px clearance covers three typical 46px Windows caption buttons plus a safety gap. The larger hit target improves mouse and touch use without changing the visual symbol.

For windows at or below 620px wide, horizontal title-bar space is constrained. Move the trigger below the caption area with `top: 62px; right: 12px`; move the settings panel to `top: 112px; right: 10px`. This avoids both native caption controls and the trigger.

The panel continues to toggle from the existing `✦` button and preserves its current controls and automatic persistence behavior.

## Opacity contract

- Default remains `0.30` (30%).
- Minimum remains `0.05` (5%).
- Maximum becomes `1.00` (100%).
- Slider step remains 1 percentage point.
- At 100%, `--miku-task-surface-opacity` becomes `0%`, making the task-page white glass base fully transparent while leaving native text and dedicated composer/readability layers intact.
- Existing settings files remain schema version 1 and require no migration.
- Values below 0.05 clamp to 0.05; values above 1.00 clamp to 1.00.

## Components

- `windows/assets/dream-skin.css`: safe trigger placement, larger hit target, no-drag/pointer behavior, and narrow-window placement.
- `windows/assets/renderer-inject.js`: slider maximum and renderer-side clamp.
- `windows/scripts/miku-settings.mjs`: persistent-settings sanitizer clamp.
- `windows/tests/miku-settings.test.mjs`: acceptance and clamping at 100%.
- `windows/tests/miku-contract-tests.ps1`: DOM/CSS contract for the trigger and slider.
- `windows/tests/renderer-inject.test.mjs`: rendered control maximum and click-toggle behavior.
- Root and Windows documentation: replace the 5%–35% range with 5%–100% and explain the 100% readability trade-off.

## Verification

1. New tests fail against the current 35% implementation.
2. Focused settings, renderer, and product contracts pass after the minimal change.
3. Full PowerShell and Node regression suites pass under `pwsh`.
4. Reinstall the managed package and verify the live trigger bounding box, no-drag style, physical safe clearance, slider maximum, and 100% persistence.
5. Verify all ten live safety/theme checks still pass.
6. Push `main` and publish patch Release `v1.0.1` with the existing automated workflow.

## Non-goals

- No new settings window, keyboard shortcut, sidebar entry, or tray process.
- No change to the 30% default.
- No schema migration or reset of existing user settings.
- No change to the official Codex title-bar controls.
