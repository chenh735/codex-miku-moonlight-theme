import fs from 'node:fs/promises';
import path from 'node:path';
import { randomUUID } from 'node:crypto';

const DEFAULT_EFFECTS = Object.freeze({
  stars: true,
  moonBreathing: true,
  cityLights: true,
  borderFlow: true,
  meteor: true,
  paused: false,
});

export const DEFAULT_SETTINGS = Object.freeze({
  schemaVersion: 1,
  taskOpacity: 0.15,
  effects: DEFAULT_EFFECTS,
});

function defaultSettings() {
  return {
    schemaVersion: DEFAULT_SETTINGS.schemaVersion,
    taskOpacity: DEFAULT_SETTINGS.taskOpacity,
    effects: { ...DEFAULT_EFFECTS },
  };
}

function booleanOrDefault(value, fallback) {
  return typeof value === 'boolean' ? value : fallback;
}

export function sanitizeSettings(value) {
  const source = value && typeof value === 'object' && !Array.isArray(value) ? value : {};
  const rawEffects = source.effects && typeof source.effects === 'object' &&
    !Array.isArray(source.effects) ? source.effects : {};
  const taskOpacity = typeof source.taskOpacity === 'number' && Number.isFinite(source.taskOpacity)
    ? Math.min(0.35, Math.max(0.05, source.taskOpacity))
    : DEFAULT_SETTINGS.taskOpacity;
  return {
    schemaVersion: 1,
    taskOpacity,
    effects: {
      stars: booleanOrDefault(rawEffects.stars, DEFAULT_EFFECTS.stars),
      moonBreathing: booleanOrDefault(rawEffects.moonBreathing, DEFAULT_EFFECTS.moonBreathing),
      cityLights: booleanOrDefault(rawEffects.cityLights, DEFAULT_EFFECTS.cityLights),
      borderFlow: booleanOrDefault(rawEffects.borderFlow, DEFAULT_EFFECTS.borderFlow),
      meteor: booleanOrDefault(rawEffects.meteor, DEFAULT_EFFECTS.meteor),
      paused: booleanOrDefault(rawEffects.paused, DEFAULT_EFFECTS.paused),
    },
  };
}

export function resolveSettingsPath(env = process.env) {
  if (!env?.LOCALAPPDATA || typeof env.LOCALAPPDATA !== 'string') {
    throw new Error('LOCALAPPDATA is required to resolve Miku theme settings');
  }
  return path.win32.join(
    env.LOCALAPPDATA,
    'CodexMikuMoonlightTheme',
    'runtime',
    'settings.json',
  );
}

function invalidSettingsPath(filePath) {
  const extension = path.extname(filePath) || '.json';
  const basename = path.basename(filePath, path.extname(filePath));
  const stamp = new Date().toISOString().replace(/[-:.]/g, '');
  return path.join(path.dirname(filePath), `${basename}.invalid-${stamp}${extension}`);
}

export async function readSettings(filePath) {
  let raw;
  try {
    raw = await fs.readFile(filePath, 'utf8');
  } catch (error) {
    if (error?.code === 'ENOENT') return defaultSettings();
    throw error;
  }

  try {
    return sanitizeSettings(JSON.parse(raw));
  } catch (error) {
    if (!(error instanceof SyntaxError)) throw error;
    await fs.rename(filePath, invalidSettingsPath(filePath));
    return defaultSettings();
  }
}

async function replaceFileAtomically(temporaryPath, filePath) {
  try {
    await fs.rename(temporaryPath, filePath);
    return;
  } catch (error) {
    if (!['EEXIST', 'EPERM', 'ENOTEMPTY'].includes(error?.code)) throw error;
  }

  const backupPath = `${temporaryPath}.replace-backup`;
  let hasBackup = false;
  try {
    await fs.rename(filePath, backupPath);
    hasBackup = true;
    await fs.rename(temporaryPath, filePath);
    await fs.rm(backupPath, { force: true });
  } catch (error) {
    if (hasBackup) {
      try {
        await fs.rm(filePath, { force: true });
        await fs.rename(backupPath, filePath);
      } catch {
        // Preserve the original error; backup remains beside the destination for recovery.
      }
    }
    throw error;
  }
}

export async function writeSettingsAtomic(filePath, value) {
  const sanitized = sanitizeSettings(value);
  const directory = path.dirname(filePath);
  await fs.mkdir(directory, { recursive: true });
  const temporaryPath = path.join(
    directory,
    `.${path.basename(filePath)}.${process.pid}.${randomUUID()}.tmp`,
  );
  let handle;
  try {
    handle = await fs.open(temporaryPath, 'wx');
    await handle.writeFile(`${JSON.stringify(sanitized, null, 2)}\n`, 'utf8');
    await handle.sync();
    await handle.close();
    handle = null;
    await replaceFileAtomically(temporaryPath, filePath);
    return sanitized;
  } finally {
    if (handle) await handle.close().catch(() => {});
    await fs.rm(temporaryPath, { force: true }).catch(() => {});
  }
}

