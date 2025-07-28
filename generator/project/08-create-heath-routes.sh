#!/bin/bash
# generator/project/08-create-health-routes.sh

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
create_health_directory() {
  log "INFO" "Creando estructura de directorios para health routes"

  if mkdir -p src/interfaces/http/health; then
    log "SUCCESS" "Directorio src/interfaces/http/health creado correctamente"
    return 0
  else
    log "ERROR" "Error al crear el directorio src/interfaces/http/health"
    return 1
  fi
}

create_health_routes_file() {
  log "INFO" "Iniciando creación del archivo health.routes.js"

  local routes_content
  routes_content="$(
    cat <<'EOF'
import express from 'express';

const router = express.Router();

router.get('/', (req, res) => {
  res.json({ status: 'ok', timestamp: Date.now() });
});

export default router;
EOF
  )"

  if write_file_with_confirm "src/interfaces/http/health/health.routes.js" "$routes_content"; then
    log "SUCCESS" "Archivo src/interfaces/http/health/health.routes.js creado correctamente"
    return 0
  else
    log "ERROR" "Error al crear el archivo src/interfaces/http/health/health.routes.js"
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

validate_route_structure() {
  log "INFO" "Validando estructura de rutas creada"

  local route_file="src/interfaces/http/health/health.routes.js"

  if [[ -f "$route_file" ]]; then
    log "SUCCESS" "Archivo de rutas health creado correctamente"

    # Verificar que el archivo contiene los elementos básicos
    if grep -q "express.Router()" "$route_file" && grep -q "export default router" "$route_file"; then
      log "SUCCESS" "Estructura de router Express validada correctamente"
    else
      log "WARN" "El archivo de rutas podría tener una estructura incompleta"
    fi
  else
    log "ERROR" "No se encontró el archivo de rutas después de la creación"
    return 1
  fi

  return 0
}

check_interfaces_structure() {
  log "INFO" "Verificando estructura de interfaces HTTP"

  local interfaces_dir="src/interfaces/http"

  if [[ -d "$interfaces_dir" ]]; then
    log "INFO" "Estructura de interfaces existente encontrada"

    # Listar subdirectorios existentes para informar al usuario
    local subdirs
    subdirs=$(find "$interfaces_dir" -mindepth 1 -maxdepth 1 -type d 2>/dev/null | wc -l)

    if [[ $subdirs -gt 0 ]]; then
      log "INFO" "Se encontraron $subdirs módulo(s) existente(s) en interfaces HTTP"
    fi
  else
    log "INFO" "Creando nueva estructura de interfaces HTTP"
  fi

  return 0
}

# ========================
# FUNCIÓN PRINCIPAL
# ========================
main() {
  log "INFO" "=== Iniciando generación de health routes ==="

  if ! validate_dependencies; then
    log "ERROR" "Falló la validación de dependencias"
    exit 1
  fi

  check_interfaces_structure

  if ! create_health_directory; then
    log "ERROR" "Error al crear la estructura de directorios"
    exit 1
  fi

  if ! create_health_routes_file; then
    log "ERROR" "Error al crear el archivo de rutas"
    exit 1
  fi

  if validate_route_structure; then
    log "SUCCESS" "=== Generación de health routes completada exitosamente ==="
  else
    log "WARN" "=== Generación completada con advertencias ==="
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
if [[ "${BASH_SOURCE[0]}" != "${0}" && (-n "${CREATE_HEALTH_ROUTES:-}" || $# -gt 0) ]]; then
  main "$@"
fi
