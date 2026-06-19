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

function slugify(text) {
  return text
    .toLowerCase()
    .replace(/[^a-z0-9]+/g, '-')
    .replace(/^-+|-+$/g, '');
}

export function showHelp() {
  banner();
  console.log(theme.white.bold('USAGE'));
  console.log('');
  console.log(`  ${theme.info('hexagonizer')}                          Interactive menu`);
  console.log(`  ${theme.info('hexagonizer init <name>')}               Initialize a project`);
  console.log(`  ${theme.info('hexagonizer entity <name>')}             Generate an entity`);
  console.log(`  ${theme.info('hexagonizer --help')}                    Show this help`);
  console.log('');
  console.log(theme.white.bold('INIT FLAGS'));
  console.log(`  ${theme.highlight('--middlewares')}       Add base middlewares (auth, roles, error handler)`);
  console.log(`  ${theme.highlight('--docker')}            Configure Docker`);
  console.log(`  ${theme.highlight('-y, --yes')}           Auto-confirm all`);
  console.log('');
  console.log(theme.white.bold('ENTITY FLAGS'));
  console.log(`  ${theme.highlight('-y, --yes')}           Auto-confirm all`);
  console.log(`  ${theme.highlight('--json [path]')}       Load fields from JSON schema file`);
  console.log('');
  console.log(theme.white.bold('EXAMPLES'));
  console.log(`  ${theme.muted('# Initialize a project with middlewares and docker')}`);
  console.log(`  hexagonizer init my-api --middlewares --docker`);
  console.log('');
  console.log(`  ${theme.muted('# Generate an entity in quick mode')}`);
  console.log(`  hexagonizer entity user -y`);
  console.log('');
  console.log(`  ${theme.muted('# Generate an entity from JSON schema')}`);
  console.log(`  hexagonizer entity product --json ./product-schema.json`);
  divider();
}

export async function headlessInit(args) {
  const projectName = args[0];
  if (!projectName) {
    console.error(theme.error('Error: project name is required'));
    console.error(`Usage: hexagonizer init <name> [--middlewares] [--docker]`);
    process.exit(1);
  }

  const sanitized = slugify(projectName);
  const scriptArgs = [];
  const env = { AUTO_YES: 'true' };

  for (let i = 1; i < args.length; i++) {
    switch (args[i]) {
      case '--middlewares':
        env.CREATE_MIDDLEWARES = 'true';
        scriptArgs.push('--middlewares');
        break;
      case '--docker':
        env.SETUP_DOCKER = 'true';
        scriptArgs.push('--docker');
        break;
      case '-y':
      case '--yes':
        env.AUTO_YES = 'true';
        break;
    }
  }

  const targetDir = path.resolve(process.cwd(), sanitized);
  if (!fs.existsSync(targetDir)) {
    fs.mkdirSync(targetDir, { recursive: true });
  }

  banner();
  console.log(theme.info(`Initializing project "${sanitized}"...\n`));

  const ok = await safeRun('scripts/init-project.sh', scriptArgs, env, { cwd: targetDir });
  if (!ok) {
    console.error(theme.error('Project initialization failed.'));
    process.exit(1);
  }
}

export async function headlessEntity(args) {
  const entityName = args[0];
  if (!entityName) {
    console.error(theme.error('Error: entity name is required'));
    console.error(`Usage: hexagonizer entity <name> [-y] [--json [path]]`);
    process.exit(1);
  }

  const scriptArgs = [entityName];
  const env = { AUTO_CONFIRM: 'true' };

  for (let i = 1; i < args.length; i++) {
    switch (args[i]) {
      case '-y':
      case '--yes':
        scriptArgs.push('-y');
        break;
      case '--json':
        scriptArgs.push('--json');
        if (i + 1 < args.length && !args[i + 1].startsWith('-')) {
          scriptArgs.push(args[++i]);
        }
        break;
    }
  }

  banner();
  console.log(theme.info(`Generating entity "${entityName}"...\n`));
  await safeRun('scripts/entity-generator.sh', scriptArgs, env);
}

const entry = process.argv[1] || '';
if (entry.endsWith('index.js')) {
  main();
}
