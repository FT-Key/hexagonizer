import path from 'node:path';
import inquirer from 'inquirer';
import { section } from './styles.js';

function slugify(text) {
  return text
    .toLowerCase()
    .replace(/[^a-z0-9]+/g, '-')
    .replace(/^-+|-+$/g, '');
}

export async function projectInitPrompt() {
  section('Project Initialization');

  const defaultName = slugify(path.basename(process.cwd()));

  const answers = await inquirer.prompt([
    {
      type: 'input',
      name: 'projectName',
      message: 'Project name:',
      default: defaultName,
      filter: (input) => slugify(input),
      validate: (input) => {
        if (!input || !slugify(input)) return 'Project name cannot be empty';
        return true;
      },
    },
    {
      type: 'input',
      name: 'description',
      message: 'Description:',
      default: 'Hexagonal architecture project',
    },
    {
      type: 'list',
      name: 'middlewares',
      message: 'Add base middlewares (auth, roles, error handler)?',
      choices: [
        { name: 'Yes', value: true },
        { name: 'No', value: false },
      ],
    },
    {
      type: 'list',
      name: 'docker',
      message: 'Set up Docker (Dockerfile + docker-compose)?',
      choices: [
        { name: 'Yes', value: true },
        { name: 'No', value: false },
      ],
    },
  ]);

  const args = [slugify(answers.projectName), answers.description || 'Hexagonal architecture project'];

  if (answers.middlewares) args.push('--middlewares');
  if (answers.docker) args.push('--docker');

  return { args, answers };
}
