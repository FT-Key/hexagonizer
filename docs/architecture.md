# Architecture

Hexagonizer es un CLI escrito en Bash que orquesta generadores de codigo Node.js. Su arquitectura es un **pipeline secuencial de modulos numerados**.

```
bin/hexagonizer (menu interactivo)
  |
  +-- scripts/init-project.sh (proyecto nuevo)
  |     |
  |     +-- generator/project/00-parse-args.sh
  |     +-- generator/project/01-check-node-and-npm.sh
  |     +-- generator/project/02-init-npm-and-install-deps.sh
  |     +-- generator/project/03-create-folders.sh
  |     +-- generator/project/04-create-base-files.sh
  |     +-- ... hasta 14-setup-docker.sh
  |
  +-- scripts/entity-generator.sh (entidad nueva)
        |
        +-- generator/entity/00-helpers.sh
        +-- generator/entity/01-parse-args.sh
        +-- generator/entity/02-load-schema.sh
        +-- generator/entity/03-generate-domain.sh
        +-- ... hasta 15-update-index.sh
```

## Pipeline de modulos

Cada modulo es un script `.sh` independiente que:

1. Se ejecuta en orden numerico (00 → 15)
2. Lee variables de entorno exportadas por modulos anteriores
3. Crea archivos o modifica el proyecto
4. Exporta nuevas variables si es necesario

## Variables compartidas

| Variable | Origen | Uso |
|----------|--------|-----|
| `AUTO_YES` | `00-parse-args.sh` (project) | Salta confirmaciones |
| `AUTO_CONFIRM` | `01-parse-args.sh` (entity) | Salta confirmaciones |
| `entity` | `02-load-schema.sh` | Nombre en snake_case |
| `EntityPascal` | `02-load-schema.sh` | Nombre en PascalCase |
| `PARSED_FIELDS` | `02-load-schema.sh` | JSON con campos parseados |
| `SCHEMA_CONTENT` | `02-load-schema.sh` | Schema JSON original |

## Convenciones de codigo

- **Bash**: `set -e`, `set -u`, colores `RED/GREEN/YELLOW/BLUE/NC`, funcion `log()` con timestamp
- **JavaScript generado**: ESM (`import`/`export`), `"type": "module"` en package.json
- **Nombres**: PascalCase para clases, camelCase para funciones, snake_case para archivos y variables Bash
- **Testing**: Node.js nativo con `assert`, sin frameworks externos
