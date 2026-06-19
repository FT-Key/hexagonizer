# CLI Reference

## Modos de uso

hexagonizer soporta dos modos:

| Modo | Uso | Destinado a |
|------|-----|-------------|
| **Interactivo** | `hexagonizer` | Humanos (menu con flechas) |
| **Headless** | `hexagonizer <comando> [flags]` | IAs y automatizacion |

---

## Modo Interactivo

Al ejecutar `hexagonizer` sin argumentos se despliega un menu interactivo con 8 opciones:

| # | Opcion | Comando interno |
|---|--------|-----------------|
| 1 | Inicializar proyecto | `scripts/init-project.sh` |
| 2 | Generar entidad (interactivo) | `scripts/entity-generator.sh` |
| 3 | Generar entidad rapida | `scripts/entity-generator.sh -y` |
| 4 | Generar desde JSON | `scripts/entity-generator.sh --json` |
| 5 | JSON + Auto-aprobar | `scripts/entity-generator.sh --json -y` |
| 6 | Servidor de desarrollo | Submenu con comandos npm/docker |
| 7 | Estadisticas del proyecto | Analisis de `src/domain/` |
| 8 | Salir | `exit 0` |

---

## Modo Headless (para IAs)

### Inicializar proyecto

```bash
hexagonizer init <nombre> [--middlewares] [--docker] [-y]
```

Crea un directorio con el nombre indicado y genera el proyecto alli.

| Flag | Efecto |
|------|--------|
| `--middlewares` | Incluye middlewares base (auth, roles, error handler) |
| `--docker` | Agrega Dockerfile + docker-compose |
| `-y`, `--yes` | Auto-confirma todo |

**Ejemplos:**
```bash
hexagonizer init my-api --middlewares --docker
hexagonizer init my-api -y
```

### Generar entidad

```bash
hexagonizer entity <nombre> [-y] [--json [path]]
```

Ejecuta contra el proyecto en el directorio actual.

| Flag | Efecto |
|------|--------|
| `-y`, `--yes` | Auto-confirma todo (modo rapido) |
| `--json [path]` | Usa schema JSON en vez de modo interactivo |

**Ejemplos:**
```bash
hexagonizer entity user -y
hexagonizer entity product --json ./schema.json
```

### Ayuda

```bash
hexagonizer --help
hexagonizer -h
```

---

## Submenu Servidor (opcion 6 del menu interactivo)

| # | Comando |
|---|---------|
| 1 | `npm start` |
| 2 | `npm run dev` |
| 3 | `npm run test` |
| 4 | `docker build -t app .` |
| 5 | `docker run -p 3000:3000 app` |
| 6 | `docker-compose up` |
| 7 | `docker-compose up -d` |
| 8 | `docker-compose down` |
| 9 | `npm install` |
| 10 | `npm run lint` |
| 11 | Volver al menu principal |

## Comportamiento

- **Deteccion de proyecto**: hexagonizer busca `package.json` en el directorio actual y padres para detectar si estas dentro de un proyecto generado
- **Modo JSON**: Busca schemas en `generator/entity/entity-schemas/` o permite ingresar una ruta personalizada
- **Estadisticas**: Cuenta entidades en `src/domain/`, archivos JS/TS, tests y dependencias npm
