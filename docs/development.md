# Development

Guia para contribuir al desarrollo del CLI hexagonizer.

## Stack

- **CLI principal**: Bash scripting
- **Utilidades**: Node.js (procesamiento de schemas JSON)
- **Codigo generado**: Node.js + Express + ESM

## Estructura del proyecto

```
bin/hexagon              # Entry point del CLI (menu interactivo)
scripts/
  init-project.sh        # Orquestador de generacion de proyectos
  entity-generator.sh    # Orquestador de generacion de entidades
generator/
  project/               # Modulos del generador de proyectos (00-14)
  entity/                # Modulos del generador de entidades (00-15)
  common/                # Funciones compartidas entre generadores
  utils/                 # Utilidades Node.js (parseo de schemas)
```

## Convenciones de codigo

### Bash
- Usar `set -e` y `set -u` en scripts
- Funcion `log(level, message)` con colores y timestamp
- Variables en UPPER_CASE para configuracion
- Citar variables siempre: `"$var"`
- Preferir `[[ ... ]]` sobre `[ ... ]`

### Modulos generadores
- Numeracion de 2 digitos (`00-`, `01-`, etc.) para orden explicito
- Cada modulo es independiente y ejecutable por separado
- Variables compartidas via `export`
- `main()` function al final para ejecucion directa o via source

### JavaScript generado
- ESM: `import`/`export`, `"type": "module"`
- Clases para entidades, factories, use cases, repositorios
- Funciones para controladores
- Tests con `assert` nativo

## Agregar un nuevo modulo

1. Crea `generator/<area>/NN-nombre.sh`
2. Sigue la numeracion existente
3. Usa las variables compartidas del pipeline
4. Manten las convenciones de logging y colores
5. Si toca el index, actualiza el orquestador correspondiente

## Probar cambios

```bash
# Ejecutar el CLI localmente
node bin/hexagon

# O directamente los generadores
bash scripts/init-project.sh -y
bash scripts/entity-generator.sh -y
```

## Schemas de entidad

Los schemas JSON de ejemplo estan en `generator/entity/entity-schemas/`.
Para agregar uno nuevo, crea un archivo JSON siguiendo el formato documentado en [entity-generator.md](entity-generator.md).

## Publicacion npm

```bash
npm publish
```

El campo `"files"` en `package.json` controla que se publica: solo `bin/`, `generator/`, `scripts/` y `README.md`.
Los archivos de configuracion de opencode (`opencode.json`, `AGENTS.md`, `.opencode/`) quedan excluidos.
