import inquirer from 'inquirer';
import { section } from './styles.js';

export async function entityPrompt() {
  section('Entity Generation');

  const { entityName } = await inquirer.prompt([
    {
      type: 'input',
      name: 'entityName',
      message: 'Entity name:',
      validate: (input) => {
        if (!input || !input.trim()) return 'Entity name cannot be empty';
        if (!/^[a-zA-Z][a-zA-Z0-9_-]*$/.test(input.trim())) {
          return 'Must start with a letter, only letters, numbers, hyphens and underscores';
        }
        return true;
      },
    },
  ]);

  const { mode } = await inquirer.prompt([
    {
      type: 'list',
      name: 'mode',
      message: 'How do you want to define the fields?',
      choices: [
        { name: 'Interactive field entry', value: 'interactive' },
        { name: 'From a JSON schema file', value: 'json' },
        { name: 'Quick mode (auto-approve all)', value: 'quick' },
      ],
    },
  ]);

  return { entityName, mode };
}
