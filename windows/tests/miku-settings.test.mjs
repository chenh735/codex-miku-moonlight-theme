import assert from 'node:assert/strict';
import fs from 'node:fs/promises';
import os from 'node:os';
import path from 'node:path';
import test from 'node:test';

let settingsModule = null;
let settingsImportError = null;
try {
  settingsModule = await import('../scripts/miku-settings.mjs');
} catch (error) {
  settingsImportError = error;
}

function subject() {
  assert.ok(settingsModule, `miku-settings.mjs must be implemented: ${settingsImportError?.message ?? 'missing'}`);
  return settingsModule;
}

async function withTempDirectory(run) {
  const directory = await fs.mkdtemp(path.join(os.tmpdir(), 'codex-miku-settings-'));
  try {
    return await run(directory);
  } finally {
    await fs.rm(directory, { recursive: true, force: true });
  }
}

test('exports the exact approved defaults', () => {
  const { DEFAULT_SETTINGS } = subject();
  assert.deepEqual(DEFAULT_SETTINGS, {
    schemaVersion: 1,
    taskOpacity: 0.30,
    effects: {
      stars: true,
      moonBreathing: true,
      cityLights: true,
      borderFlow: true,
      meteor: true,
      paused: false,
    },
  });
});

test('sanitizes opacity and discards unknown keys', () => {
  const { sanitizeSettings } = subject();
  assert.deepEqual(sanitizeSettings({
    schemaVersion: 99,
    taskOpacity: 0.23,
    ignored: 'discard me',
    effects: {
      stars: false,
      moonBreathing: false,
      cityLights: false,
      borderFlow: false,
      meteor: false,
      paused: true,
      extra: true,
    },
  }), {
    schemaVersion: 1,
    taskOpacity: 0.23,
    effects: {
      stars: false,
      moonBreathing: false,
      cityLights: false,
      borderFlow: false,
      meteor: false,
      paused: true,
    },
  });
});

test('clamps finite numeric opacity to five through thirty-five percent', () => {
  const { sanitizeSettings } = subject();
  assert.equal(sanitizeSettings({ taskOpacity: -1 }).taskOpacity, 0.05);
  assert.equal(sanitizeSettings({ taskOpacity: 2 }).taskOpacity, 0.35);
  assert.equal(sanitizeSettings({ taskOpacity: Number.NaN }).taskOpacity, 0.30);
  assert.equal(sanitizeSettings({ taskOpacity: '0.2' }).taskOpacity, 0.30);
});

test('invalid effect values fall back to approved booleans', () => {
  const { sanitizeSettings } = subject();
  const result = sanitizeSettings({
    effects: {
      stars: 'false',
      moonBreathing: 0,
      cityLights: null,
      borderFlow: undefined,
      meteor: true,
      paused: false,
    },
  });
  assert.deepEqual(result.effects, {
    stars: true,
    moonBreathing: true,
    cityLights: true,
    borderFlow: true,
    meteor: true,
    paused: false,
  });
});

test('resolves the theme-local runtime settings path', () => {
  const { resolveSettingsPath } = subject();
  assert.equal(
    resolveSettingsPath({ LOCALAPPDATA: 'C:\\Users\\Miku\\AppData\\Local' }),
    path.win32.join(
      'C:\\Users\\Miku\\AppData\\Local',
      'CodexMikuMoonlightTheme',
      'runtime',
      'settings.json',
    ),
  );
  assert.throws(() => resolveSettingsPath({}), /LOCALAPPDATA/);
});

test('missing settings return a fresh default object', async () => {
  const { DEFAULT_SETTINGS, readSettings } = subject();
  await withTempDirectory(async (directory) => {
    const first = await readSettings(path.join(directory, 'settings.json'));
    const second = await readSettings(path.join(directory, 'settings.json'));
    assert.deepEqual(first, DEFAULT_SETTINGS);
    assert.deepEqual(second, DEFAULT_SETTINGS);
    assert.notEqual(first, second);
    assert.notEqual(first.effects, second.effects);
  });
});

test('malformed JSON is quarantined and defaults are returned', async () => {
  const { DEFAULT_SETTINGS, readSettings } = subject();
  await withTempDirectory(async (directory) => {
    const filePath = path.join(directory, 'settings.json');
    await fs.writeFile(filePath, '{not-json', 'utf8');
    const result = await readSettings(filePath);
    assert.deepEqual(result, DEFAULT_SETTINGS);
    await assert.rejects(fs.access(filePath));
    const entries = await fs.readdir(directory);
    assert.equal(entries.length, 1);
    assert.match(entries[0], /^settings\.invalid-\d{8}T\d{6}\d{3}Z\.json$/);
    assert.equal(await fs.readFile(path.join(directory, entries[0]), 'utf8'), '{not-json');
  });
});

test('atomic writes leave valid sanitized JSON and no temp artifact', async () => {
  const { writeSettingsAtomic } = subject();
  await withTempDirectory(async (directory) => {
    const filePath = path.join(directory, 'nested', 'settings.json');
    const written = await writeSettingsAtomic(filePath, {
      taskOpacity: 0.27,
      effects: { stars: false, paused: true },
      ignored: true,
    });
    assert.equal(written.taskOpacity, 0.27);
    assert.deepEqual(JSON.parse(await fs.readFile(filePath, 'utf8')), written);
    await writeSettingsAtomic(filePath, { taskOpacity: 0.31 });
    const entries = await fs.readdir(path.dirname(filePath));
    assert.deepEqual(entries, ['settings.json']);
  });
});
