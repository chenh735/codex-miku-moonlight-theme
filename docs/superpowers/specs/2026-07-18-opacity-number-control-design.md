# Miku Opacity Number Control Design

Date: 2026-07-18
Status: Approved interaction direction; awaiting written-spec confirmation

## Goal

Replace the unreliable native task-opacity range slider with a compact, keyboard-accessible numeric control that always accepts values from 5 through 100 and preserves the user's existing saved opacity.

## User interface

The settings panel keeps the existing `任务背景透明度` label. The range slider and separate percentage output are removed. In their place, one control group displays:

`－ [ numeric input ] ＋`

- The numeric input uses `type="number"`, `min="5"`, `max="100"`, and `step="1"`.
- The minus and plus buttons decrease or increase the value by one percentage point.
- Buttons and input are explicit interactive `no-drag` regions with normal pointer behavior.
- The control fits the existing 310 px settings panel and remains usable at the current narrow-window breakpoint.
- No draggable slider, custom track, or pointer-capture implementation remains.

## Behavior and data flow

- The current saved value is shown when the panel mounts. The user's current 38% setting is not reset.
- Clicking `－` or `＋` applies and persists the new value immediately.
- Pressing Enter in the numeric input, changing focus, or using the input's native stepper applies and persists the value.
- While the user is typing an incomplete value, the theme does not write invalid intermediate data.
- Empty, non-finite, or otherwise invalid input restores the last valid value.
- Values below 5 clamp to 5; values above 100 clamp to 100.
- Every accepted value continues through the existing `applyMikuSettings` bridge, revision counter, sanitizer, and atomic settings writer.
- Renderer reinjection and settings reload keep the numeric input synchronized with the persisted opacity.

## Accessibility

- The control group has an accessible opacity label.
- The decrement and increment buttons have explicit Chinese `aria-label` values.
- Enter commits the typed value; Escape restores the last valid value.
- Focus remains on the numeric input after a keyboard commit and is not moved by background reinjection.

## Files

- `windows/assets/renderer-inject.js`: replace the range/output construction and event handlers with numeric input plus decrement/increment buttons.
- `windows/assets/dream-skin.css`: replace range styling with compact number-control styling and no-drag interaction rules.
- `windows/tests/renderer-inject.test.mjs`: cover mount, clamping, button steps, Enter/Escape, and settings synchronization.
- `windows/tests/miku-contract-tests.ps1`: require the numeric control contract and forbid the old range slider contract.
- User documentation and changelogs: describe direct 5–100 entry and the v1.0.2 change.

## Verification

1. New tests fail against the v1.0.1 range-slider implementation.
2. Focused renderer and contract tests pass after the minimal replacement.
3. The full PowerShell and Node suites pass under PowerShell 7 and Windows PowerShell 5.1 compatibility checks.
4. The managed package is reinstalled without resetting the saved 38% value.
5. Live checks verify `－`, direct entry, `＋`, 5/100 clamping, persistence, route reinjection, and all ten safety/theme checks.
6. The user's chosen value is restored after boundary tests.
7. Push `main` and publish patch Release `v1.0.2` with verified ZIP and SHA256 assets.

## Non-goals

- No slider or drag interaction.
- No new settings window, tray process, shortcut, schema version, or migration.
- No change to the 30% default for fresh installations.
- No reset of existing settings or motion-effect choices.
