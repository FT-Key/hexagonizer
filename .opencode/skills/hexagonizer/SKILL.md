---
name: hexagonizer
description: Generador de proyectos Node.js con arquitectura hexagonal. Usa este skill cuando el usuario pida crear un proyecto con DDD, hexagonal, o entidades CRUD.
license: MIT
---

# Hexagonizer — AI Usage Guide

Hexagonizer es un CLI que genera proyectos Node.js con **arquitectura hexagonal** (Domain, Application, Infrastructure, HTTP interfaces, tests).

## Cuando usar este skill

Usa hexagonizer cuando el usuario pida:

- "Crear un proyecto con arquitectura hexagonal"
- "Inicializar un proyecto Node.js con DDD"
- "Generar entidades CRUD con validaciones y tests"
- "Scaffolding de API REST con Express + capas"
- Cualquier mencion de "hexagonal", "DDD", "puertos y adaptadores"

No lo uses para proyectos frontend, React, Vue, o APIs que no necesiten DDD.

## Instalacion

```bash
npm install -g hexagonizer
```

## Comandos headless (para IAs)

Todos los comandos funcionan sin interaccion humana:

### Inicializar proyecto

```bash
hexagonizer init <nombre> [--middlewares] [--docker]
```

Crea un directorio `<nombre>` con el proyecto dentro.

| Flag | Descripcion |
|------|-------------|
| `--middlewares` | Incluye auth, roles, error handler, rate limiter |
| `--docker` | Agrega Dockerfile + docker-compose |
| `-y, --yes` | Auto-confirmar todo |

**Ejemplo:**
```bash
hexagonizer init my-api --middlewares --docker
```

### Generar entidad

Ejecutar DENTRO del directorio del proyecto generado.

```bash
hexagonizer entity <nombre> [-y] [--json [path]]
```

Crea: Domain class, Factory, Validation, Repository (in-memory), Use Cases (CRUD), Controller, Routes, Tests.

| Flag | Descripcion |
|------|-------------|
| `-y, --yes` | Auto-confirmar (modo rapido, campos por defecto) |
| `--json [path]` | Definir campos desde schema JSON |

**Ejemplos:**
```bash
cd my-api
hexagonizer entity user -y
hexagonizer entity product --json ./product-schema.json
```

### Ayuda

```bash
hexagonizer --help
```

## Modo interactivo (para humanos)

```bash
hexagonizer
```

Sin argumentos muestra un menu con flechas: Init, Entity, JSON, Server commands, Stats.

## Flujo tipico AI

```
1. Instalar: npm install -g hexagonizer
2. Crear proyecto: hexagonizer init mi-proyecto --middlewares --docker
3. Entrar al directorio: cd mi-proyecto
4. Generar entidades: hexagonizer entity usuario -y
                     hexagonizer entity producto -y
5. El proyecto generado tiene Express, tests, y todo interconectado
```

## Estructura generada

```
mi-proyecto/
├── src/
│   ├── domain/{entity}/       # Entidad, Factory, Validation, Constants
│   ├── application/{entity}/  # Use cases (create, get, update, delete, list)
│   ├── infrastructure/{entity}/ # Repositorios (in-memory, database)
│   ├── interfaces/http/{entity}/ # Controller, Routes
│   ├── middlewares/            # Auth, roles, error handler
│   └── config/                # DB config, etc.
└── tests/application/{entity}/ # Tests unitarios por use case
```

## Notas importantes

- Requiere **bash** (Unix/Linux, WSL en Windows, o Git Bash)
- El proyecto generado usa ESM (`"type": "module"`) y Express
- Las entidades se generan con campos por defecto (id, active, createdAt, updatedAt)
- Los tests usan `assert` nativo de Node.js — sin frameworks externos
- Los use cases, rutas y middlewares se wirean automaticamente al servidor
