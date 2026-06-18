---
name: project-structure
description: Estructura del generador hexagonizer (CLI) y de los proyectos que genera con arquitectura hexagonal
license: MIT
---

## Proyecto hexagonizer (el CLI tool)

```
hexagonizer/
├── bin/
│   └── hexagon                # Entry point del CLI (Bash, registrado en package.json bin)
├── generator/
│   ├── common/                 # Utils compartidos entre generadores
│   │   ├── confirm-action.sh   # Confirmacion interactiva
│   │   ├── generate-query-middlewares.sh
│   │   └── generate-query-utils.sh
│   ├── entity/                 # Pipeline de generacion de entidades
│   │   ├── 00-helpers.sh       # Funciones auxiliares
│   │   ├── 01-parse-args.sh    # Parseo de argumentos
│   │   ├── 02-load-schema.sh   # Carga schema JSON
│   │   ├── 03-generate-domain.sh      # Entidad de dominio
│   │   ├── 04-generate-validation.sh   # Validacion
│   │   ├── 05-generate-factory.sh      # Factory
│   │   ├── 06-generate-constants.sh    # Constantes
│   │   ├── 07-generate-repository.sh   # Repositorios
│   │   ├── 08-generate-usecases.sh     # Casos de uso
│   │   ├── 09-generate-services.sh     # Servicios
│   │   ├── 10-generate-controller.sh   # Controladores
│   │   ├── 11-generate-routes.sh       # Rutas Express
│   │   ├── 12-generate-query-entity-config.sh
│   │   ├── 13-generate-query-middlewares-and-utils.sh
│   │   ├── 14-generate-tests.sh        # Tests
│   │   ├── 15-update-index.sh          # Actualiza index.js
│   │   └── entity-schemas/             # Schemas JSON de ejemplo
│   ├── project/                # Pipeline de generacion de proyectos
│   │   ├── 00-parse-args.sh
│   │   ├── 01-check-node-and-npm.sh
│   │   ├── 02-init-npm-and-install-deps.sh
│   │   ├── 03-create-folders.sh
│   │   ├── 04-create-base-files.sh
│   │   ├── 05-create-index-and-server.sh
│   │   ├── 06-generate-base-middlewares.sh
│   │   ├── 07-generate-query-utils.sh
│   │   ├── 08-generate-database-config.sh
│   │   └── 09-setup-docker.sh
│   └── utils/                  # Utilidades Node.js
│       ├── filter-query-fields.js
│       ├── normalizer-dos-to-unix.sh
│       └── parse-schema-fields.js
├── scripts/
│   ├── entity-generator.sh     # Orquestador de generacion de entidades
│   └── init-project.sh         # Orquestador de inicializacion de proyectos
├── bin/
│   └── hexagon                 # Entry point CLI
```

## Proyecto GENERADO por hexagonizer

Cuando ejecutas `hexagonizer init`, se crea un proyecto con esta estructura:

```
mi-proyecto/
├── src/
│   ├── domain/
│   │   └── {entity}/
│   │       ├── {entity}.js         # Entidad (clase con getters/setters)
│   │       ├── {entity}-factory.js # Factory para crear entidades
│   │       ├── {entity}-validation.js # Validacion de campos
│   │       ├── {entity}-constants.js  # Constantes y enumeraciones
│   │       └── mocks.js            # Datos mock para desarrollo
│   │
│   ├── application/
│   │   └── {entity}/
│   │       └── use-cases/
│   │           ├── create-{entity}.js
│   │           ├── get-{entity}.js
│   │           ├── update-{entity}.js
│   │           ├── delete-{entity}.js
│   │           ├── deactivate-{entity}.js
│   │           └── list-{entity}.js
│   │
│   ├── infrastructure/
│   │   └── {entity}/
│   │       ├── in-memory-{entity}-repository.js
│   │       └── database-{entity}-repository.js
│   │
│   ├── interfaces/
│   │   └── http/
│   │       └── {entity}/
│   │           ├── {entity}.controller.js
│   │           └── {entity}.routes.js
│   │
│   └── utils/
│       ├── query-utils.js
│       └── query-middlewares.js
│
├── src/
│   ├── middlewares/
│   │   ├── auth.js
│   │   ├── error-handler.js
│   │   └── role.js
│   ├── config/
│   │   └── database.js
│   ├── app.js o index.js       # Entry point Express
│   ├── docker-compose.yml
│   └── Dockerfile
```

## Convenciones de codigo generado

- **Entidades**: Clases JS con `_` prefijo en props privadas, getters/setters, metodo `toJSON()`, `activate()`/`deactivate()`
- **Use cases**: Clases con constructor que recibe repository, metodo `execute()`
- **Repositorios**: `save()`, `findById()`, `findAll()`, `update()`, `deleteById()`, `deactivateById()`, `count()`
- **Controladores**: Funciones async `(req, res) =>`, instancian use case, try/catch con next(error)
- **Rutas**: Express Router, una ruta por accion
- **Tests**: Por cada use case, test unitario con InMemoryRepository
- **Modulos**: ESM (`import`/`export`), `"type": "module"` en package.json

## Flujo tipico de datos

```
Request HTTP
  → Route (Express Router)
    → Controller (valida params, llama use case)
      → Use Case (orquesta logica de negocio)
        → Entity (valida reglas de dominio)
          → Repository (persiste datos)
    → Response JSON
```

## Reglas de dependencia

```
domain/         → nada (logica pura, sin imports de infraestructura)
application/    → domain/ (usa entidades y repositorios)
infrastructure/ → domain/ (implementa repositorios)
interfaces/     → application/ (llama a use cases)
```
