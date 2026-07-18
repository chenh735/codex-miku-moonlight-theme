# Settings Trigger and 100% Opacity Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Make the Miku settings trigger reliably clickable in Codex for Windows and extend task background opacity control from 5%–35% to 5%–100% without changing the 30% default.

**Architecture:** Keep the existing renderer-injected settings panel and schema. Move the trigger outside the native caption-control hit area, explicitly opt it out of draggable regions, and widen the same opacity value contract in both renderer and persistent-settings sanitizer.

**Tech Stack:** CSS, vanilla JavaScript, Node.js tests, PowerShell contract tests, GitHub Actions release workflow.

---

## Task 1: Extend the opacity data contract to 100%

**Files:**
- Modify: `windows/tests/miku-settings.test.mjs`
- Modify: `windows/tests/renderer-inject.test.mjs`
- Modify: `windows/tests/miku-contract-tests.ps1`
- Modify: `windows/scripts/miku-settings.mjs`
- Modify: `windows/assets/renderer-inject.js`

- [ ] Update sanitizer tests to require a 5% minimum, 100% maximum, and acceptance of `1.0`.
- [ ] Update renderer and contract tests to require slider `max="100"` and `--miku-task-surface-opacity: 0%` at 100%.
- [ ] Run the focused tests and confirm they fail for the existing 35% implementation.
- [ ] Change renderer-side and persistent-settings clamps from `0.35` to `1` and change the range maximum to `100`.
- [ ] Re-run the focused tests and confirm they pass.
- [ ] Commit as `feat: extend task opacity to 100 percent`.

## Task 2: Move and harden the settings trigger

**Files:**
- Modify: `windows/tests/miku-contract-tests.ps1`
- Modify: `windows/assets/dream-skin.css`

- [ ] Add CSS contract tests for the 44×44 target, `right: 154px`, explicit no-drag behavior, pointer cursor, touch action, and narrow-window placement.
- [ ] Run the focused contract test and confirm it fails against the existing top-right 36×36 trigger.
- [ ] Implement the normal-width safe placement and interaction properties.
- [ ] Add the ≤620px trigger placement below the caption area and move the panel below it.
- [ ] Re-run the focused and renderer tests and confirm they pass.
- [ ] Commit as `fix: keep Miku settings trigger clear of window controls`.

## Task 3: Update documentation and release contracts

**Files:**
- Modify: `README.md`
- Modify: `README.en.md`
- Modify: `CHANGELOG.md`
- Modify: `docs/installation.md`
- Modify: `windows/CHANGELOG.md`
- Modify: `windows/SKILL.md`
- Modify: `windows/references/qa-inventory.md`
- Modify: `windows/tests/miku-product-contract-tests.ps1`
- Modify: `windows/tests/repository-contract-tests.ps1`

- [ ] Update product/repository contract tests to require the 5%–100% range.
- [ ] Confirm the updated tests fail while documentation still states 5%–35%.
- [ ] Document the new range, 30% default, 100% readability trade-off, and corrected trigger location.
- [ ] Add v1.0.1 changelog entries describing both fixes.
- [ ] Run all PowerShell and Node test suites under `pwsh`.
- [ ] Commit as `docs: document clickable settings and full opacity range`.

## Task 4: Package, live-verify, and publish v1.0.1

**Files:**
- Verify/package: `windows/`
- Verify: `.github/workflows/release.yml`

- [ ] Build the Windows package and reinstall it into the managed local theme installation.
- [ ] Verify against the live Codex renderer: trigger is 44×44, has at least 154px right clearance, resolves as the center hit target, has `pointer` cursor and `-webkit-app-region: no-drag`, toggles the panel, and exposes slider maximum 100.
- [ ] Verify 100% persists and produces `--miku-task-surface-opacity: 0%`, then restore the user's current 30% setting.
- [ ] Re-run all ten live safety/theme checks.
- [ ] Merge the isolated worktree branch into `main`, then push using the configured local proxy on port 7897.
- [ ] Tag and push `v1.0.1`, wait for the release workflow, and verify the published asset checksum.
