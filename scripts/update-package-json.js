#!/usr/bin/env node
import { readFileSync, writeFileSync } from 'fs';
const path = './package.json';

function loadPackage() {
  try {
    const data = readFileSync(path, 'utf8');
    return JSON.parse(data);
  } catch (e) {
    console.error('Error leyendo package.json:', e.message);
    process.exit(1);
  }
}

function savePackage(pkg) {
  try {
    writeFileSync(path, JSON.stringify(pkg, null, 2) + '\n');
  } catch (e) {
    console.error('Error guardando package.json:', e.message);
    process.exit(1);
  }
}

const pkg = loadPackage();

pkg.scripts = pkg.scripts || {};
if (!pkg.scripts.start) pkg.scripts.start = 'node src/index.js';
if (!pkg.scripts.dev) pkg.scripts.dev = 'nodemon src/index.js';

if (pkg.type !== 'module') {
  pkg.type = 'module';
}

savePackage(pkg);

console.log('✅ package.json actualizado');
