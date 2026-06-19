# Hexagonizer

CLI tool for scaffolding Node.js projects with a clean **hexagonal architecture** — domain, application, infrastructure, HTTP interfaces, and automated tests.

Designed for both **humans** (interactive menu) and **AI agents** (headless CLI commands) to rapidly bootstrap production-ready projects with DDD principles.

---

## Installation

```bash
npm install -g hexagonizer
```

---

## Usage — Human mode

Run without arguments for an interactive menu:

```bash
hexagonizer
```

Select options with arrow keys: **Init project**, **Generate entity**, **Server commands**, **Stats**.

---

## Usage — AI / Headless mode

All commands work non-interactively with flags. Perfect for AI agents (opencode, claudecode) and automation.

### Initialize a project

```bash
hexagonizer init <name> [--middlewares] [--docker]
```

Creates a directory with the project inside.

| Flag | Description |
|------|-------------|
| `--middlewares` | Include auth, roles, error handler |
| `--docker` | Add Dockerfile + docker-compose |
| `-y, --yes` | Auto-confirm all |

**Example:**
```bash
hexagonizer init my-api --middlewares --docker
```

### Generate an entity

Run **inside** the generated project directory.

```bash
hexagonizer entity <name> [-y] [--json [path]]
```

Creates: Domain class, Factory, Validation, Repository, Use cases (CRUD), Controller, Routes, Tests.

| Flag | Description |
|------|-------------|
| `-y, --yes` | Quick mode (auto-approve default fields) |
| `--json [path]` | Define fields from a JSON schema file |

**Examples:**
```bash
cd my-api
hexagonizer entity user -y
hexagonizer entity product --json ./product-schema.json
```

### Help

```bash
hexagonizer --help
```

---

## Typical AI workflow

```bash
# 1. Install
npm install -g hexagonizer

# 2. Scaffold project with middlewares and docker
hexagonizer init my-store-api --middlewares --docker

# 3. Generate entities
cd my-store-api
hexagonizer entity user -y
hexagonizer entity product -y
hexagonizer entity order -y

# 4. Start developing
npm run dev
```

The generated project comes with Express preconfigured, routes wired, tests ready, and everything connected.

---

## Generated project structure

```
my-project/
├── src/
│   ├── domain/
│   │   └── <entity>/
│   │       ├── <Entity>.js
│   │       ├── <entity>-factory.js
│   │       ├── <entity>-validation.js
│   │       └── <entity>-constants.js
│   ├── application/
│   │   └── <entity>/
│   │       └── use-cases/
│   │           ├── create-<entity>.js
│   │           ├── get-<entity>.js
│   │           ├── update-<entity>.js
│   │           ├── delete-<entity>.js
│   │           └── list-<entity>.js
│   ├── infrastructure/
│   │   └── <entity>/
│   │       ├── in-memory-<entity>-repository.js
│   │       └── database-<entity>-repository.js
│   ├── interfaces/http/
│   │   ├── <entity>/
│   │   │   ├── <entity>.controller.js
│   │   │   └── <entity>.routes.js
│   │   └── middlewares/
│   │       ├── auth.js
│   │       ├── error-handler.js
│   │       └── role.js
│   ├── config/
│   └── index.js
├── tests/
│   └── application/<entity>/
└── package.json
```

---

## AI integration

Hexagonizer ships with an **opencode skill** that teaches AI agents how to use it. When working with opencode inside a project, the AI can load the skill:

```
skill({ name: "hexagonizer" })
```

This gives the AI full context on commands, flags, and the generated project structure. The skill is auto-detected when opencode scans `.opencode/skills/`.

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
| Interactive CLI (human mode) | Complete |
| Headless CLI (AI / automation mode) | Complete |
| Base project initialization | Complete |
| Generic entity generation | Complete |
| Dynamic validations | Complete |
| Query middlewares (`q`, etc.) | Complete |
| Automated tests per entity | Complete |
| JSON schema entity generation | Partial |
| AI skill for opencode | Complete |
| Global npm installation | Complete |

---

## Requirements

- **bash** (Linux, macOS, WSL on Windows, or Git Bash)
- **Node.js** 18+ (for generated projects)
- **npm** (for dependency installation)

---

## Contributing

Contributions, ideas, and bug reports are welcome. Open an issue or submit a pull request.

---

## License

MIT — 2025 Franco Toledo
