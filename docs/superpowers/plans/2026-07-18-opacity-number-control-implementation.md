# Miku Opacity Number Control Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Replace the task-opacity slider with a reliable `－ [5–100 numeric input] ＋` control while preserving current settings and the 30% fresh-install default.

**Architecture:** Keep the existing renderer settings bridge, revision counter, sanitizer, and atomic writer. Only the renderer control and its CSS change: a commit helper validates a complete numeric value, buttons step the current valid percentage, and synchronization avoids overwriting an actively edited input.

**Tech Stack:** Vanilla JavaScript renderer injection, CSS, Node.js VM tests, PowerShell contract tests, GitHub Actions.

## Global Constraints

- Numeric range is exactly 5 through 100 with integer step 1.
- Existing saved opacity, currently 38%, must not be reset during install or reinjection.
- Fresh installations keep the 30% default and settings schema version 1.
- No slider, drag logic, pointer capture, new window, tray process, shortcut, or migration.
- Release target is v1.0.2.

---

### Task 1: Test the numeric control through the renderer fixture

**Files:**
- Modify: `windows/tests/renderer-inject.test.mjs`
- Modify: `windows/tests/miku-contract-tests.ps1`

**Interfaces:**
- Consumes: renderer-owned elements marked with `data-miku-setting` and the existing `window.__CODEX_MIKU_THEME_SETTINGS__` bridge.
- Produces: a VM fixture capable of mounting and interacting with the actual settings DOM; contract assertions that forbid `type="range"` and require number/min/max/step plus decrement/increment labels.

- [ ] **Step 1: Upgrade the VM element fixture before writing behavior assertions**

Extend fake elements with child storage, attributes, recursive `querySelector`, `appendChild`, event registration/dispatch, `click`, and `focus`. Track `document.activeElement` so the production synchronization guard is testable. The selector matcher only needs the existing data-attribute selectors:

```js
const listeners = new Map();
const children = [];
const attributes = new Map();
const matches = (node, selector) => {
  const dataMatch = /^\[([^=]+)="([^"]+)"\]$/.exec(selector);
  return Boolean(dataMatch && node.attributes.get(dataMatch[1]) === dataMatch[2]);
};

appendChild(child) { child.parentElement = this; children.push(child); return child; }
addEventListener(type, listener) {
  const bucket = listeners.get(type) ?? [];
  bucket.push(listener);
  listeners.set(type, bucket);
}
dispatchEvent(event) {
  event.target ??= this;
  for (const listener of listeners.get(event.type) ?? []) listener.call(this, event);
  return true;
}
querySelector(selector) {
  for (const child of children) {
    if (matches(child, selector)) return child;
    const nested = child.querySelector?.(selector);
    if (nested) return nested;
  }
  return null;
}
```

- [ ] **Step 2: Write failing renderer behavior tests**

Mount with `taskOpacity: .38`, locate the number input and both buttons by data attributes, and assert:

```js
assert.equal(opacityInput.type, "number");
assert.equal(opacityInput.min, "5");
assert.equal(opacityInput.max, "100");
assert.equal(opacityInput.step, "1");
assert.equal(opacityInput.value, "38");

decrement.click();
assert.equal(settingsFixture.rootStyles.get("--miku-task-opacity"), "0.37");
increment.click();
assert.equal(settingsFixture.rootStyles.get("--miku-task-opacity"), "0.38");

opacityInput.value = "101";
opacityInput.dispatchEvent({ type: "change" });
assert.equal(opacityInput.value, "100");
assert.equal(settingsFixture.rootStyles.get("--miku-task-opacity"), "1.00");

opacityInput.value = "";
opacityInput.dispatchEvent({ type: "change" });
assert.equal(opacityInput.value, "100");

opacityInput.value = "4";
opacityInput.dispatchEvent({ type: "keydown", key: "Enter", preventDefault() {} });
assert.equal(opacityInput.value, "5");

opacityInput.value = "77";
opacityInput.dispatchEvent({ type: "keydown", key: "Escape", preventDefault() {} });
assert.equal(opacityInput.value, "5");
```

Add PowerShell contracts requiring `input.type = "number"`, `data-miku-opacity-decrement`, `data-miku-opacity-increment`, and the Chinese aria labels; forbid `input.type = "range"`.

- [ ] **Step 3: Run tests and verify RED**

Run:

```powershell
node .\windows\tests\renderer-inject.test.mjs
pwsh -NoProfile -File .\windows\tests\miku-contract-tests.ps1
```

Expected: renderer assertions cannot find the new controls and the contract reports the missing numeric-control markers.

### Task 2: Replace the slider with the numeric stepper

**Files:**
- Modify: `windows/assets/renderer-inject.js`
- Modify: `windows/assets/dream-skin.css`
- Test: `windows/tests/renderer-inject.test.mjs`
- Test: `windows/tests/miku-contract-tests.ps1`

**Interfaces:**
- Consumes: `normalizeMikuSettings(value)` and `applyMikuSettings(value, { bumpRevision: true })`.
- Produces: `data-miku-setting="taskOpacity"` number input, `data-miku-opacity-decrement` button, and `data-miku-opacity-increment` button.

- [ ] **Step 1: Replace renderer construction and synchronization**

Build a labeled number-control group:

```js
const opacityRow = createMikuElement("div", "codex-miku-opacity-control");
const opacityLabel = createMikuElement("span", "", "任务背景透明度");
opacityLabel.id = "codex-miku-opacity-label";
const stepper = createMikuElement("div", "codex-miku-opacity-stepper");
const decrement = createMikuElement("button", "codex-miku-opacity-button", "－");
decrement.type = "button";
decrement.setAttribute("data-miku-opacity-decrement", "true");
decrement.setAttribute("aria-label", "降低任务背景透明度");
const input = createMikuElement("input", "codex-miku-opacity-input");
input.type = "number";
input.min = "5";
input.max = "100";
input.step = "1";
input.inputMode = "numeric";
input.setAttribute("data-miku-setting", "taskOpacity");
input.setAttribute("aria-labelledby", opacityLabel.id);
const increment = createMikuElement("button", "codex-miku-opacity-button", "＋");
increment.type = "button";
increment.setAttribute("data-miku-opacity-increment", "true");
increment.setAttribute("aria-label", "提高任务背景透明度");
```

In `applyMikuSettings`, update the number input only when it is not the active element:

```js
if (opacity && document.activeElement !== opacity) {
  opacity.value = String(Math.round(mikuSettings.taskOpacity * 100));
}
```

- [ ] **Step 2: Implement validation, button steps, and keyboard behavior**

Use one commit helper and one restore helper:

```js
const currentOpacityPercent = () => Math.round(mikuSettings.taskOpacity * 100);
const restoreOpacityInput = () => { input.value = String(currentOpacityPercent()); };
const commitOpacityInput = () => {
  const candidate = Number(input.value);
  if (!Number.isFinite(candidate) || input.value.trim() === "") {
    restoreOpacityInput();
    return false;
  }
  const percent = Math.min(100, Math.max(5, Math.round(candidate)));
  const next = normalizeMikuSettings(mikuSettings);
  next.taskOpacity = percent / 100;
  applyMikuSettings(next, { bumpRevision: true });
  input.value = String(percent);
  return true;
};
```

Wire `change`, Enter, Escape, and both buttons. Buttons derive from the current saved percentage so invalid typed text cannot poison stepping.

- [ ] **Step 3: Replace slider CSS with compact no-drag stepper CSS**

Use a two-row control with a three-column stepper. The buttons are pointer controls and the number field remains a text cursor:

```css
html.codex-miku-theme .codex-miku-opacity-control {
  display: grid;
  gap: 8px;
  margin: 10px 0 12px;
}

html.codex-miku-theme .codex-miku-opacity-stepper {
  display: grid;
  grid-template-columns: 42px minmax(0, 1fr) 42px;
  gap: 8px;
}

html.codex-miku-theme .codex-miku-opacity-stepper > * {
  min-height: 38px;
  pointer-events: auto;
  -webkit-app-region: no-drag;
}
```

Style buttons consistently with the reset control, center the numeric value, and remove all range-specific CSS.

- [ ] **Step 4: Run focused tests and verify GREEN**

Run the two focused commands from Task 1. Expected: both exit 0; button, boundary, Enter/Escape, current-value, and forbidden-slider assertions pass.

- [ ] **Step 5: Commit**

```powershell
git add windows/assets/renderer-inject.js windows/assets/dream-skin.css windows/tests/renderer-inject.test.mjs windows/tests/miku-contract-tests.ps1
git commit -m "fix: replace opacity slider with numeric controls"
```

### Task 3: Document, install, and publish v1.0.2

**Files:**
- Modify: `README.md`
- Modify: `README.en.md`
- Modify: `docs/installation.md`
- Modify: `CHANGELOG.md`
- Modify: `windows/CHANGELOG.md`
- Modify: `windows/references/qa-inventory.md`
- Modify: `windows/tests/miku-product-contract-tests.ps1`
- Modify: `windows/tests/repository-contract-tests.ps1`

**Interfaces:**
- Consumes: the published numeric control contract from Task 2.
- Produces: user instructions and v1.0.2 release assets.

- [ ] **Step 1: Write failing documentation contracts**

Require Chinese docs to contain `－ [数值输入框] ＋` and English docs to describe direct 5–100 numeric entry. Require QA to test decrement, direct entry, increment, 5/100 clamping, Enter/Escape, persistence, and reinjection.

- [ ] **Step 2: Run documentation contracts and verify RED**

Run:

```powershell
pwsh -NoProfile -File .\windows\tests\repository-contract-tests.ps1
pwsh -NoProfile -File .\windows\tests\miku-product-contract-tests.ps1
```

Expected: fail because v1.0.1 documentation still describes only the generic opacity panel.

- [ ] **Step 3: Update documentation and changelogs**

Document direct numeric entry and buttons, remove drag instructions, and add v1.0.2 entries. Keep the 5–100 range, 30% default, and 100% readability warning.

- [ ] **Step 4: Run full automated verification**

```powershell
pwsh -NoProfile -File .\windows\tests\run-tests.ps1
```

Expected: exit 0. Fault-injection cleanup warnings are expected test fixtures; no test may fail.

- [ ] **Step 5: Commit documentation**

```powershell
git add README.md README.en.md docs/installation.md CHANGELOG.md windows/CHANGELOG.md windows/references/qa-inventory.md windows/tests/miku-product-contract-tests.ps1 windows/tests/repository-contract-tests.ps1
git commit -m "docs: document direct opacity entry"
```

- [ ] **Step 6: Install and live-verify without resetting the user value**

Record settings, build `1.0.2`, run `Install.ps1`, reapply through the verified 9335 loopback session, and assert the saved value remains 38%. Live-test minus, direct entry, plus, invalid restoration, 5/100 clamping, Enter/Escape, persistence, reinjection, and the ten existing verification checks. Restore 38% after boundary tests.

- [ ] **Step 7: Merge, push, and publish**

Merge the isolated branch into `main`, rerun the full suite, push with proxy `http://127.0.0.1:7897`, tag `v1.0.2`, wait for the release workflow, and verify the public ZIP against its `.sha256` asset.
