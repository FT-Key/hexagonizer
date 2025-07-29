#!/bin/bash
# generator/project/10-create-router-wrapper.sh

set -e

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
# INITIALIZATION
# ========================
init_environment() {
  SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
  PROJECT_ROOT="$(cd "$SCRIPT_DIR/../.." && pwd)"

  log "INFO" "Inicializando entorno para crear router wrapper"
  log "INFO" "Directorio del script: $SCRIPT_DIR"
  log "INFO" "Directorio raíz del proyecto: $PROJECT_ROOT"

  # Source del archivo de confirmación
  if [[ -f "$PROJECT_ROOT/generator/common/confirm-action.sh" ]]; then
    source "$PROJECT_ROOT/generator/common/confirm-action.sh"
    log "SUCCESS" "Archivo confirm-action.sh cargado correctamente"
  else
    log "ERROR" "No se encontró el archivo confirm-action.sh"
    return 1
  fi
}

# ========================
# DIRECTORY CREATION
# ========================
create_directories() {
  local target_dir="src/utils"

  log "INFO" "Creando directorio: $target_dir"

  if mkdir -p "$target_dir"; then
    log "SUCCESS" "Directorio creado correctamente: $target_dir"
  else
    log "ERROR" "Error al crear el directorio: $target_dir"
    return 1
  fi
}

# ========================
# FILE CONTENT GENERATION
# ========================
generate_router_wrapper_content() {
  cat <<'EOF'
import express from 'express';
import { match } from 'path-to-regexp';

export function wrapRouterWithFlexibleMiddlewares(router, options = {}) {
  const {
    globalMiddlewares = [],
    excludePathsByMiddleware = {},
    routeMiddlewares = {},
  } = options;

  const wrapped = express.Router();

  globalMiddlewares.forEach((mw) => {
    const mwName = mw.name || 'anonymous';
    wrapped.use((req, res, next) => {
      const excludes = excludePathsByMiddleware[mwName] || [];
      if (excludes.some(path => match(path)(req.path))) {
        return next();
      }
      return mw(req, res, next);
    });
  });

  wrapped.use((req, res, next) => {
    for (const pattern in routeMiddlewares) {
      const isMatch = match(pattern)(req.path);
      if (isMatch) {
        const mws = routeMiddlewares[pattern];
        let i = 0;
        const run = (i) => {
          if (i >= mws.length) return next();
          mws[i](req, res, () => run(i + 1));
        };
        return run(0);
      }
    }
    return next();
  });

  wrapped.use(router);
  return wrapped;
}
EOF
}

# ========================
# FILE CREATION
# ========================
create_router_wrapper_file() {
  local file_path="src/utils/wrap-router-with-flexible-middlewares.js"
  local content

  log "INFO" "Generando contenido para el router wrapper"
  content=$(generate_router_wrapper_content)

  log "INFO" "Creando archivo: $file_path"

  if write_file_with_confirm "$file_path" "$content"; then
    log "SUCCESS" "Router wrapper creado correctamente: $file_path"
  else
    log "ERROR" "Error al crear el router wrapper: $file_path"
    return 1
  fi
}

# ========================
# MAIN FUNCTION
# ========================
main() {
  log "INFO" "Iniciando proceso de creación del router wrapper"

  # Inicializar entorno
  if ! init_environment; then
    log "ERROR" "Error en la inicialización del entorno"
    exit 1
  fi

  # Crear directorios
  if ! create_directories; then
    log "ERROR" "Error al crear directorios"
    exit 1
  fi

  # Crear archivo del router wrapper
  if ! create_router_wrapper_file; then
    log "ERROR" "Error al crear router wrapper"
    exit 1
  fi

  log "SUCCESS" "Proceso de creación del router wrapper completado exitosamente"
}

# ========================
# EXECUTION LOGIC
# ========================
# Si se llama directamente con bash
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
  main "$@"
fi

# Si se hace source y hay condiciones específicas
if [[ "${BASH_SOURCE[0]}" != "${0}" && (-n "${CREATE_ROUTER_WRAPPER:-}" || $# -gt 0) ]]; then
  main "$@"
fi
