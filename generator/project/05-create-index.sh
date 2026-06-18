#!/bin/bash
# generator/project/05-create-index.sh

set -e
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "$SCRIPT_DIR/../.." && pwd)"

source "$SCRIPT_DIR/../common/logging.sh"
source "$PROJECT_ROOT/generator/common/confirm-action.sh"

main() {
  write_file_with_confirm "src/index.js" \
'import { Server } from "./config/server.js";

import healthRoutes from "./interfaces/http/health/health.routes.js";
import publicRoutes from "./interfaces/http/public/public.routes.js";

import { wrapRouterWithFlexibleMiddlewares } from "./utils/wrap-router-with-flexible-middlewares.js";

const excludePathsByMiddleware = {};
const routeMiddlewares = {};
const globalMiddlewares = [];

const healthRouter = wrapRouterWithFlexibleMiddlewares(healthRoutes, {
  globalMiddlewares,
  excludePathsByMiddleware,
  routeMiddlewares,
});

const publicRouter = wrapRouterWithFlexibleMiddlewares(publicRoutes, {
  globalMiddlewares,
  excludePathsByMiddleware,
  routeMiddlewares,
});

const server = new Server({
  middlewares: [],
  routes: [
    { path: "/health", handler: healthRouter },
    { path: "/public", handler: publicRouter },
  ],
});

server.start(process.env.PORT || 3000);
'
  log "SUCCESS" "Punto de entrada creado (src/index.js)"
}

if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
  main "$@"
fi

if [[ "${BASH_SOURCE[0]}" != "${0}" && (-n "${CREATE_INDEX:-}" || $# -gt 0) ]]; then
  main "$@"
fi
