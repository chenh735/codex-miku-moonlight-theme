import fs from 'node:fs';
import path from 'node:path';
import { fileURLToPath } from 'node:url';

const root = path.dirname(path.dirname(fileURLToPath(import.meta.url)));
const pngPath = path.join(root, 'assets', 'miku-music-mark.png');
const icoPath = path.join(root, 'assets', 'miku-music-mark.ico');
const required = [16, 20, 24, 32, 48, 64, 128, 256];

function assert(condition, message) {
  if (!condition) throw new Error(message);
}

assert(fs.existsSync(pngPath), `Missing reference PNG: ${pngPath}`);
assert(fs.existsSync(icoPath), `Missing Windows icon: ${icoPath}`);

const png = fs.readFileSync(pngPath);
assert(
  png.subarray(0, 8).equals(Buffer.from([137, 80, 78, 71, 13, 10, 26, 10])),
  'Invalid PNG signature',
);
assert(
  png.readUInt32BE(16) === 1024 && png.readUInt32BE(20) === 1024,
  'Reference PNG must be 1024x1024',
);

const ico = fs.readFileSync(icoPath);
assert(ico.readUInt16LE(0) === 0 && ico.readUInt16LE(2) === 1, 'Invalid ICO header');
const count = ico.readUInt16LE(4);
assert(count === required.length, `Expected ${required.length} ICO frames, got ${count}`);

const sizes = [];
for (let index = 0; index < count; index += 1) {
  const entry = 6 + index * 16;
  const width = ico[entry] || 256;
  const height = ico[entry + 1] || 256;
  const length = ico.readUInt32LE(entry + 8);
  const offset = ico.readUInt32LE(entry + 12);
  assert(width === height, `ICO frame ${index} is not square`);
  assert(offset + length <= ico.length, `ICO frame ${index} exceeds file bounds`);
  assert(
    ico.subarray(offset, offset + 8).equals(Buffer.from([137, 80, 78, 71, 13, 10, 26, 10])),
    `ICO frame ${index} is not PNG encoded`,
  );
  sizes.push(width);
}

assert(JSON.stringify(sizes) === JSON.stringify(required), `Unexpected ICO sizes: ${sizes.join(', ')}`);
console.log('PASS: Miku music-mark PNG and ICO dimensions are valid.');
