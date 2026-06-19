import { spawn } from 'node:child_process';
import fs from 'node:fs';
import { fileURLToPath } from 'node:url';
import { dirname, resolve } from 'node:path';
import { theme } from './styles.js';

const __dirname = dirname(fileURLToPath(import.meta.url));
const ROOT = resolve(__dirname, '..');

export function runScript(scriptRelPath, args = [], env = {}, options = {}) {
  return new Promise((resolvePromise, reject) => {
    const scriptPath = resolve(ROOT, scriptRelPath);

    if (!fs.existsSync(scriptPath)) {
      reject(new Error(`Script not found: ${scriptPath}`));
      return;
    }

    const child = spawn('bash', [scriptPath, ...args], {
      cwd: options.cwd || process.cwd(),
      stdio: ['inherit', 'inherit', 'pipe'],
      env: {
        ...process.env,
        ...env,
      },
    });

    let stderr = '';
    child.stderr.on('data', (data) => {
      stderr += data.toString();
    });

    child.on('close', (code) => {
      if (code === 0) {
        resolvePromise();
      } else {
        reject(new Error(stderr || `Script exited with code ${code}`));
      }
    });

    child.on('error', (err) => {
      reject(new Error(`Failed to start script: ${err.message}`));
    });
  });
}

export function runCommand(cmd, args = [], options = {}) {
  return new Promise((resolvePromise, reject) => {
    const child = spawn(cmd, args, {
      cwd: process.cwd(),
      stdio: options.stdio ?? 'inherit',
      env: { ...process.env, ...options.env },
      shell: options.shell ?? true,
    });

    child.on('close', (code) => {
      if (code === 0) resolvePromise();
      else reject(new Error(`Command exited with code ${code}`));
    });

    child.on('error', (err) => reject(err));
  });
}

export async function safeRun(scriptRelPath, args = [], env = {}, options = {}) {
  console.log(theme.info(`Running ${scriptRelPath}...`));
  try {
    await runScript(scriptRelPath, args, env, options);
    console.log(theme.success('Done\n'));
    return true;
  } catch (err) {
    console.error(theme.error(`Error: ${err.message}\n`));
    return false;
  }
}
