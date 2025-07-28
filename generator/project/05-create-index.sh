#!/bin/bash
# generator/project/05-create-index.sh

# ========================
# CONFIGURACIÓN INICIAL
# ========================
set -e
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "$SCRIPT_DIR/../.." && pwd)"

# ========================
# COLORES PARA OUTPUT
# ========================
if [[ -z "${RED:-}" ]]; then
  readonly RED='\033[0;31m'
  readonly GREEN='\033[0;32m'
  readonly YELLOW='\033[1;33m'
  readonly BLUE='\033[0;34m'
  readonly NC='\033[0m' # No Color
fi

# ========================
# LOGGING FUNCTION
# ========================
log() {
  local level="$1"
  shift
  local message="$*"
  local timestamp
  timestamp=$(date '+%Y-%m-%d %H:%M:%S')

  case "$level" in
  "INFO") printf "${BLUE}[INFO]${NC}    %s - %s\n" "$timestamp" "$message" ;;
  "SUCCESS") printf "${GREEN}[SUCCESS]${NC} %s - %s\n" "$timestamp" "$message" ;;
  "WARN") printf "${YELLOW}[WARN]${NC}    %s - %s\n" "$timestamp" "$message" ;;
  "ERROR") printf "${RED}[ERROR]${NC}   %s - %s\n" "$timestamp" "$message" >&2 ;;
  esac
}

# ========================
# DEPENDENCIAS
# ========================
source "$PROJECT_ROOT/generator/common/confirm-action.sh"

# ========================
# FUNCIONES PRINCIPALES
# ========================
create_index_file() {
  log "INFO" "Iniciando creación del archivo index.js"

  local index_content
  index_content="$(
    cat <<'EOF'
import { Server } from './config/server.js';

import healthRoutes from './interfaces/http/health/health.routes.js';
import publicRoutes from './interfaces/http/public/public.routes.js';

import { wrapRouterWithFlexibleMiddlewares } from './utils/wrap-router-with-flexible-middlewares.js';

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
    { path: '/health', handler: healthRouter },
    { path: '/public', handler: publicRouter },
  ],
});

server.start(process.env.PORT || 3000);
EOF
  )"

  if write_file_with_confirm "src/index.js" "$index_content"; then
    log "SUCCESS" "Archivo src/index.js creado correctamente"
    return 0
  else
    log "ERROR" "Error al crear el archivo src/index.js"
    return 1
  fi
}

validate_dependencies() {
  log "INFO" "Validando dependencias necesarias"

  if [[ ! -f "$PROJECT_ROOT/generator/common/confirm-action.sh" ]]; then
    log "ERROR" "No se encontró el archivo confirm-action.sh"
    return 1
  fi

  log "SUCCESS" "Todas las dependencias están disponibles"
  return 0
}

# ========================
# FUNCIÓN PRINCIPAL
# ========================
main() {
  log "INFO" "=== Iniciando generación de index.js ==="

  if ! validate_dependencies; then
    log "ERROR" "Falló la validación de dependencias"
    exit 1
  fi

  if create_index_file; then
    log "SUCCESS" "=== Generación de index.js completada exitosamente ==="
  else
    log "ERROR" "=== Error durante la generación de index.js ==="
    exit 1
  fi
}

# ========================
# EXECUTION LOGIC
# ========================
# Si se llama directamente con bash
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
  main "$@"
fi

# Si se hace source y hay condiciones específicas
if [[ "${BASH_SOURCE[0]}" != "${0}" && (-n "${CREATE_INDEX:-}" || $# -gt 0) ]]; then
  main "$@"
fi
