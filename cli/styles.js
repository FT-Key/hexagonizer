import chalk from 'chalk';

export const theme = {
  primary: chalk.hex('#4A90D9'),
  secondary: chalk.hex('#7C5CBF'),
  success: chalk.hex('#2ECC71'),
  warning: chalk.hex('#F39C12'),
  error: chalk.hex('#E74C3C'),
  info: chalk.hex('#5DADE2'),
  muted: chalk.hex('#7F8C8D'),
  white: chalk.hex('#ECF0F1'),
  highlight: chalk.hex('#F1C40F'),
};

export function banner() {
  const line = '─'.repeat(50);
  const pad = (s) => {
    const total = 50 - s.length;
    const left = Math.floor(total / 2);
    const right = total - left;
    return ' '.repeat(left) + s + ' '.repeat(right);
  };
  const green = chalk.hex('#00FF88');

  console.log('');
  console.log(green(`┌${line}┐`));
  console.log(green.bold(`│${pad('HEXAGONIZER')}│`));
  console.log(green(`│${chalk.dim(pad('Clean Architecture Made Easy'))}│`));
  console.log(green(`└${line}┘`));
  console.log('');
}

export function section(title) {
  const line = '─'.repeat(50);
  console.log('');
  console.log(chalk.hex('#7C5CBF').bold(`┌${line}┐`));
  console.log(chalk.hex('#7C5CBF').bold(`│ ${title}${' '.repeat(47 - title.length)}│`));
  console.log(chalk.hex('#7C5CBF').bold(`└${line}┘`));
  console.log('');
}

export function divider() {
  console.log(chalk.dim('─'.repeat(52)));
  console.log('');
}
