import inquirer from 'inquirer';
import { banner } from './styles.js';

export async function showMainMenu() {
  banner();

  const { action } = await inquirer.prompt([
    {
      type: 'list',
      name: 'action',
      message: 'What do you want to do?',
      pageSize: 8,
      loop: false,
      choices: [
        { name: 'Initialize a new project', value: 'init' },
        { name: 'Generate a new entity (interactive)', value: 'entity' },
        { name: 'Quick entity generation (auto-approve)', value: 'entity-quick' },
        { name: 'Generate entity from JSON', value: 'entity-json' },
        { name: 'JSON + auto-approve', value: 'entity-json-yes' },
        { name: 'Development server', value: 'server' },
        { name: 'Project statistics', value: 'stats' },
        { name: 'Exit', value: 'exit' },
      ],
    },
  ]);

  return action;
}
