# 初音未来·月光都市 QA inventory

## User-visible claims

1. Home shows the approved UI-free Miku moonlight artwork, a live title, four glass action cards, the native sidebar, and the native composer.
2. Each action card only populates the native composer. It never sends, submits, presses Enter, or clicks a send control.
3. Task routes reuse the artwork as a visible glass-backed ambient layer. Opacity defaults to 30% and is adjustable across the complete 5%–35% range.
4. Stars, moon breathing, city lights, border flow, and meteor effects are independent. Pause-all and `prefers-reduced-motion` stop animation without changing saved choices.
5. Sidebar, header, composer, project controls, terminal, diff, dialogs, and scroll remain native and interactive.
6. The theme survives route changes and renderer reloads while the verified injector runs.
7. Restore removes injected DOM/CSS and closes the saved CDP listener before reopening official Codex.

## Functional checks

- Home cards: click each card, compare the exact prompt, and confirm the send action remains untouched.
- Composer: type, edit and clear text normally after a card populates it.
- Opacity: verify 5%, 23%, 30% and 35%; restart at 23% and confirm persistence.
- Effect isolation: switch each effect independently, then test pause-all and system reduced motion.
- Navigation: open a task, return home, open project selection, terminal and diff, and confirm no duplicate Miku DOM.
- Resize: test wide, approximately 900 px, and approximately 620 px layouts.
- Auxiliary windows: confirm non-shell windows stay transparent and receive no theme root class.
- Restore/reapply: remove the live theme, verify official mode, then apply and verify again.
- Update resilience: package discovery must resolve the current signed `OpenAI.Codex` package dynamically.
- Restart consent: an existing normal Codex window is not force-closed without the approved CLI flag or shortcut confirmation.
- Shortcut policy: only the launcher and restore shortcuts are installed; both use `RemoteSigned`.
- Theme safety: malformed JSON, oversized images, invalid dimensions, traversal and reparse points fail closed.

## Visual checks

- Miku remains on the right; the left title safe area stays readable.
- The approved bitmap is never stretched or person-animated.
- Glass panels retain readable contrast in light and dark appearances.
- Task text, code, diff and terminal content remain readable over the 30% background and linked glass surface.
- Decorations never intercept pointer input.
- Reject black sidebar artifacts, clipped controls, duplicate composers, horizontal overflow, weak contrast, or rasterized native controls.

## Automated checks

- `tests/miku-product-contract-tests.ps1`
- `tests/miku-contract-tests.ps1`
- `tests/run-tests.ps1`
- `node --test tests/miku-settings.test.mjs`
- `node --check scripts/injector.mjs`
- `node --check scripts/miku-settings.mjs`
- `node --check assets/renderer-inject.js`

Live Windows signoff remains required for Store process ownership, restart consent, visual layout, settings persistence, restore, reapply, and CDP closure.
