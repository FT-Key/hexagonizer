#!/bin/bash
# generator/project/06-create-server.sh

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
create_public_directory() {
  log "INFO" "Creando directorio src/public"

  if mkdir -p src/public; then
    log "SUCCESS" "Directorio src/public creado correctamente"
    return 0
  else
    log "ERROR" "Error al crear el directorio src/public"
    return 1
  fi
}

create_server_file() {
  log "INFO" "Iniciando creación del archivo server.js"

  local server_content
  server_content="$(
    cat <<'EOF'
import express from 'express';
import path from 'path';
import { fileURLToPath } from 'url';

const __filename = fileURLToPath(import.meta.url);
const __dirname = path.dirname(__filename);

export class Server {
  constructor({ routes = [], middlewares = [] } = {}) {
    this.app = express();
    this.routes = routes;
    this.middlewares = middlewares;
  }

  setupMiddlewares() {
    this.app.use(express.json());
    this.app.use(express.static(path.resolve(__dirname, '../public')));
    this.middlewares.forEach((mw) => this.app.use(mw));
  }

  setupRoutes() {
    this.routes.forEach(({ path: routePath, handler }) => {
      this.app.use(routePath, handler);
    });

    this.app.get('/', (req, res) => {
      res.sendFile(path.resolve(__dirname, '../public/index.html'));
    });
  }

  start(port = 3000) {
    this.setupMiddlewares();
    this.setupRoutes();
    this.app.listen(port, () => {
      console.log(`🚀 Servidor iniciado en http://localhost:${port}`);
    });
  }

  getApp() {
    return this.app;
  }
}
EOF
  )"

  if write_file_with_confirm "src/config/server.js" "$server_content"; then
    log "SUCCESS" "Archivo src/config/server.js creado correctamente"
    return 0
  else
    log "ERROR" "Error al crear el archivo src/config/server.js"
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

create_config_directory() {
  log "INFO" "Creando directorio src/config"

  if mkdir -p src/config; then
    log "SUCCESS" "Directorio src/config creado correctamente"
    return 0
  else
    log "ERROR" "Error al crear el directorio src/config"
    return 1
  fi
}

# ========================
# FUNCIÓN PRINCIPAL
# ========================
main() {
  log "INFO" "=== Iniciando generación de servidor ==="

  if ! validate_dependencies; then
    log "ERROR" "Falló la validación de dependencias"
    exit 1
  fi

  if ! create_public_directory; then
    log "ERROR" "Error al crear directorio público"
    exit 1
  fi

  if ! create_config_directory; then
    log "ERROR" "Error al crear directorio de configuración"
    exit 1
  fi

  if create_server_file; then
    log "SUCCESS" "=== Generación de servidor completada exitosamente ==="
  else
    log "ERROR" "=== Error durante la generación del servidor ==="
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
if [[ "${BASH_SOURCE[0]}" != "${0}" && (-n "${CREATE_SERVER:-}" || $# -gt 0) ]]; then
  main "$@"
fi
