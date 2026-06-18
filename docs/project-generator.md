# Project Generator

`hexagonizer init` crea un proyecto Node.js + Express listo para desarrollar.

## Estructura generada

```
mi-proyecto/
├── src/
│   ├── index.js                     # Entry point: crea Server, monta rutas
│   ├── config/
│   │   ├── server.js                # Clase Server: middlewares + rutas + start
│   │   └── database.js              # Placeholder de configuracion DB
│   ├── domain/                      # Entidades (vacio hasta generar)
│   ├── application/                 # Casos de uso (vacio hasta generar)
│   ├── infrastructure/
│   │   └── database/
│   │       └── database.js          # Placeholder de conexion DB
│   ├── interfaces/
│   │   └── http/
│   │       ├── health/
│   │       │   └── health.routes.js # GET /health → { status: 'ok' }
│   │       ├── public/
│   │       │   └── public.routes.js # GET /info → metadata del proyecto
│   │       └── middlewares/         # Auth, roles, error handler, etc.
│   ├── utils/
│   │   ├── query-utils.js           # applyFilters, applySearch, applySort, applyPagination
│   │   └── wrap-router-with-flexible-middlewares.js
│   └── public/
│       └── index.html               # Landing page animada con hexagono 3D
├── tests/
│   └── application/                 # Tests de casos de uso
├── Dockerfile                       # node:18, npm install, expone 3000
├── docker-compose.yml               # Servicio con hot-reload volumem
├── .dockerignore
└── package.json
```

## Server class

```javascript
class Server {
  constructor({ routes, middlewares })
  // 1. setupMiddlewares() → express.json(), cors, helmet, morgan, custom mws
  // 2. setupRoutes() → monta cada ruta con wrapRouterWithFlexibleMiddlewares
  // 3. start(port) → app.listen(port)
}
```

## Middlewares base (opcionales)

Si se confirma durante `init`, se generan:

| Middleware | Funcion |
|-----------|---------|
| `auth.middleware.js` | Valida Bearer token |
| `check-role.middleware.js` | `checkRole()` y `checkRoleOrOwner()` |
| `error-handler.middleware.js` | Captura errores, responde JSON |
| `rate-limiter.middleware.js` | Limita 100 req / 15 min |
| `request-logger.middleware.js` | Log de method + URL |
| `sanitize.middleware.js` | XSS clean + mongo sanitize |

## Router wrapper

`wrapRouterWithFlexibleMiddlewares(router, config)` permite aplicar middlewares globales, por ruta o excluyendo paths especificos usando `path-to-regexp`.

## Dependencias instaladas

**Produccion**: `express`, `path-to-regexp`, `cors`, `helmet`, `morgan`, `dotenv`

**Desarrollo**: `nodemon`

## Docker

- `Dockerfile` con Node 18
- `docker-compose.yml` con volumen montado para desarrollo en caliente
- Acceso rapido desde el menu de hexagonizer (opcion 6)
