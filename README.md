# Hexagonizer

CLI tool for scaffolding Node.js projects with a clean **hexagonal architecture** — domain, application, infrastructure, HTTP interfaces, and automated tests.

> **Work in Progress** — Active development. Some features are complete, others are under construction.

---

## Overview

Hexagonizer generates a ready-to-use Node.js project structured around domain-driven principles. It provides an interactive CLI (built with [Inquirer](https://github.com/SBoudrias/Inquirer.js)) and styled terminal output (using [Chalk](https://github.com/chalk/chalk)).

### What it does

- **Initializes a base project** with:
  - Hexagonal folder structure
  - Preconfigured Express server
  - Common middlewares (`auth`, `checkRole`, `rateLimiter`, etc.)
  - Auto-wired routes and controllers
  - Simple welcome frontend (`index.html`)

- **Generates complete entities** ready to use:
  - Domain class with base fields (`id`, `active`, `createdAt`, etc.)
  - In-Memory repository
  - Use cases (`create`, `update`, `get`, `delete`, `deactivate`)
  - Dynamic validations based on attributes
  - Full unit tests
  - Filter, sort, and search configuration (`queryConfig`)
  - Routes and middlewares integrated into the server

- **Supports entity generation from JSON schema** (partial)

---

## Installation

```bash
npm install -g hexagonizer
```

This installs the global command:

```bash
hexagonizer
```

---

## Usage

### Initialize a new project

```bash
hexagonizer
```

Select **"Init project"** and follow the interactive prompts.

### Generate a generic entity

```bash
hexagonizer
```

Select **"Generate entity"** and enter a name (e.g., `user`).

This creates the following structure:

```
src/
  domain/user/User.js
  application/user/
  infrastructure/user/
  interfaces/http/user/
tests/application/user/
```

Everything is wired automatically to the server and middlewares.

### Generate entity from JSON schema (WIP)

```bash
hexagonizer
```

Select **"Generate entity from JSON schema"** and provide the file path.

> Note: This feature is still in development. Some generated files may require manual adjustments.

---

## Generated project structure

```
hexagon-project/
├── src/
│   ├── domain/
│   ├── application/
│   ├── infrastructure/
│   ├── interfaces/
│   │   └── http/
│   │       ├── middlewares/
│   │       └── <entity>/
│   ├── config/
│   └── index.js
├── tests/
│   └── application/<entity>/
└── package.json
```

---

## Built with

| Dependency | Purpose |
|---|---|
| [Inquirer](https://github.com/SBoudrias/Inquirer.js) | Interactive CLI prompts and menus |
| [Chalk](https://github.com/chalk/chalk) | Terminal text styling and colors |
| [Express](https://expressjs.com) | HTTP server (generated projects) |

---

## Feature status

| Feature | Status |
|---|---|
| Interactive CLI | Complete |
| Base project initialization | Complete |
| Generic entity generation | Complete |
| Dynamic validations | Complete |
| Query middlewares (`q`, etc.) | Complete |
| Automated tests per entity | Complete |
| JSON schema entity generation | Partial |
| Script modularization | Complete |
| Global npm installation | Complete (v1.1.0+) |

---

## Contributing

Contributions, ideas, and bug reports are welcome. Open an issue or submit a pull request.

---

## License

MIT — 2025 Franco Toledo
