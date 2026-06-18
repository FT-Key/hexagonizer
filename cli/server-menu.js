import chalk from 'chalk';
import inquirer from 'inquirer';
import { section } from './styles.js';
import { safeRun, runCommand } from './runner.js';

async function serverAction(cmd, label, isLongRunning) {
  console.log('');
  try {
    if (isLongRunning) {
      console.log(`Starting ${label}... Press Ctrl+C to stop.\n`);
      await runCommand(cmd, [], { stdio: 'inherit' });
    } else {
      console.log(`Running ${label}...\n`);
      await runCommand(cmd, [], { stdio: 'inherit' });
    }
  } catch (err) {
    console.error(`Command finished with code: ${err.message}`);
  }
}

export async function showServerMenu() {
  section('Development Server');

  const { option } = await inquirer.prompt([
    {
      type: 'list',
      name: 'option',
      message: 'Select an option:',
      pageSize: 12,
      loop: false,
      choices: [
        new inquirer.Separator(chalk.hex('#5DADE2').dim('── Node.js ──')),
        { name: 'npm start (production)', value: 'npm-start' },
        { name: 'npm run dev (development with nodemon)', value: 'npm-dev' },
        { name: 'npm run test (run tests)', value: 'npm-test' },
        new inquirer.Separator(chalk.hex('#1ABC9C').dim('── Docker ──')),
        { name: 'docker build -t hexagonizer .', value: 'docker-build' },
        { name: 'docker run -p 3000:3000 hexagonizer', value: 'docker-run' },
        { name: 'docker-compose up', value: 'docker-up' },
        { name: 'docker-compose up -d (background)', value: 'docker-up-d' },
        { name: 'docker-compose down', value: 'docker-down' },
        new inquirer.Separator(chalk.hex('#7F8C8D').dim('── Additional ──')),
        { name: 'npm install (install dependencies)', value: 'npm-install' },
        { name: 'npm run lint (check code quality)', value: 'npm-lint' },
        { name: 'Back to main menu', value: 'back' },
      ],
    },
  ]);

  switch (option) {
    case 'npm-start': await serverAction('npm start', 'production server', true); break;
    case 'npm-dev': await serverAction('npm run dev', 'dev server', true); break;
    case 'npm-test': await serverAction('npm run test', 'tests', false); break;
    case 'docker-build': await serverAction('docker build -t hexagonizer .', 'Docker build', false); break;
    case 'docker-run': await serverAction('docker run -p 3000:3000 hexagonizer', 'Docker run', true); break;
    case 'docker-up': await serverAction('docker-compose up', 'Docker Compose up', true); break;
    case 'docker-up-d': await serverAction('docker-compose up -d', 'Docker Compose background', false); break;
    case 'docker-down': await serverAction('docker-compose down', 'Docker Compose down', false); break;
    case 'npm-install': await serverAction('npm install', 'npm install', false); break;
    case 'npm-lint': await serverAction('npm run lint', 'linter', false); break;
    case 'back': return 'back';
  }

  return 'continue';
}
