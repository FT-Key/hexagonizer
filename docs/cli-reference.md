# CLI Reference

## Menu principal

Al ejecutar `hexagonizer` se despliega un menu interactivo con 8 opciones:

| # | Opcion | Flag | Comando interno |
|---|--------|------|-----------------|
| 1 | Inicializar proyecto | `-y` | `scripts/init-project.sh` |
| 2 | Generar entidad (interactivo) | — | `scripts/entity-generator.sh` |
| 3 | Generar entidad rapida | `-y` | `scripts/entity-generator.sh -y` |
| 4 | Generar desde JSON | `--json` | `scripts/entity-generator.sh --json` |
| 5 | JSON + Auto-aprobar | `--json -y` | `scripts/entity-generator.sh --json -y` |
| 6 | Servidor de desarrollo | — | Submenu con comandos npm/docker |
| 7 | Estadisticas del proyecto | — | Analisis de `src/domain/` |
| 8 | Salir | — | `exit 0` |

## Flags

| Flag | Efecto |
|------|--------|
| `-y`, `--yes` | Auto-responde "si" a todas las confirmaciones |
| `--json` | Usa schema JSON file en vez de modo interactivo |

## Submenu Servidor (opcion 6)

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
