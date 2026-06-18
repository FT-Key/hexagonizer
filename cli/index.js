import fs from 'node:fs';
import path from 'node:path';
import { banner, divider, theme } from './styles.js';
import { showMainMenu } from './main-menu.js';
import { safeRun } from './runner.js';
import { projectInitPrompt } from './project-init.js';
import { entityPrompt } from './entity-prompt.js';
import { showServerMenu } from './server-menu.js';

function countFiles(dir, ext) {
  if (!fs.existsSync(dir)) return 0;
  let count = 0;
  try {
    const entries = fs.readdirSync(dir, { withFileTypes: true });
    for (const entry of entries) {
      const full = path.join(dir, entry.name);
      if (entry.isDirectory() && entry.name !== 'node_modules') {
        count += countFiles(full, ext);
      } else if (entry.isFile() && entry.name.endsWith(ext)) {
        count++;
      }
    }
  } catch {}
  return count;
}

async function showStats() {
  banner();
  console.log(theme.highlight.bold('Project Statistics'));
  console.log('');
  const cwd = process.cwd();

  let projectRoot = null;
  let dir = cwd;
  let pkg = null;
  while (dir !== path.dirname(dir)) {
    try {
      const raw = fs.readFileSync(path.join(dir, 'package.json'), 'utf-8');
      pkg = JSON.parse(raw);
      projectRoot = dir;
      break;
    } catch {
      dir = path.dirname(dir);
    }
  }

  if (!pkg) {
    console.log(theme.error('No package.json found in current or parent directories'));
    return;
  }

  console.log(`${theme.info('Project:')} ${theme.white.bold(pkg.name || 'N/A')}`);
  console.log(`${theme.info('Version:')} ${theme.white.bold(pkg.version || 'N/A')}`);
  console.log('');

  const srcDir = path.join(projectRoot, 'src');
  if (fs.existsSync(srcDir) && fs.statSync(srcDir).isDirectory()) {
    const domainDir = path.join(projectRoot, 'src/domain');
    if (fs.existsSync(domainDir)) {
      const entities = fs.readdirSync(domainDir)
        .filter((f) => fs.statSync(path.join(domainDir, f)).isDirectory());
      console.log(`${theme.info('Entities:')} ${theme.white.bold(String(entities.length))}`);
      if (entities.length > 0) {
        entities.forEach((e) => console.log(`  ${theme.muted(e)}`));
      }
      console.log('');
    }

    const jsFiles = countFiles(srcDir, '.js');
    const tsFiles = countFiles(srcDir, '.ts');
    console.log(`${theme.info('JS files:')} ${theme.white.bold(String(jsFiles))}`);
    console.log(`${theme.info('TS files:')} ${theme.white.bold(String(tsFiles))}`);
  } else {
    console.log(theme.muted('No src/ directory found'));
  }

  divider();
}

export async function main() {
  while (true) {
    const action = await showMainMenu();

    switch (action) {
      case 'init': {
        const { args, answers } = await projectInitPrompt();
        const env = {
          AUTO_YES: 'true',
          CREATE_MIDDLEWARES: answers.middlewares ? 'true' : 'false',
          SETUP_DOCKER: answers.docker ? 'true' : 'false',
        };
        const ok = await safeRun('scripts/init-project.sh', args, env);
        if (!ok) {
          console.log(theme.error('Project initialization failed. Check the errors above.'));
        }
        break;
      }
      case 'entity': {
        const { entityName, mode } = await entityPrompt();
        const args = [entityName];
        if (mode === 'json') args.push('--json');
        if (mode === 'quick') args.push('-y');
        await safeRun('scripts/entity-generator.sh', args, { AUTO_CONFIRM: 'true' });
        break;
      }
      case 'entity-quick':
        await safeRun('scripts/entity-generator.sh', ['-y'], { AUTO_CONFIRM: 'true' });
        break;
      case 'entity-json':
        await safeRun('scripts/entity-generator.sh', ['--json'], { AUTO_CONFIRM: 'true' });
        break;
      case 'entity-json-yes':
        await safeRun('scripts/entity-generator.sh', ['--json', '-y'], { AUTO_CONFIRM: 'true' });
        break;
      case 'server':
        await showServerMenu();
        break;
      case 'stats':
        await showStats();
        break;
      case 'exit':
        console.log(theme.success('\nGoodbye!\n'));
        process.exit(0);
    }
  }
}

const entry = process.argv[1] || '';
if (entry.endsWith('index.js')) {
  main();
}
