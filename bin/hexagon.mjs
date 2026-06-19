#!/usr/bin/env node
import { main, showHelp, headlessInit, headlessEntity } from '../cli/index.js';

const args = process.argv.slice(2);

if (args.length === 0) {
  main();
} else {
  switch (args[0]) {
    case 'init':
      await headlessInit(args.slice(1));
      break;
    case 'entity':
      await headlessEntity(args.slice(1));
      break;
    case '--help':
    case '-h':
      showHelp();
      break;
    default:
      showHelp();
      process.exit(1);
  }
}
