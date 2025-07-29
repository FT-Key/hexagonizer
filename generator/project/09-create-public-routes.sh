#!/bin/bash
# generator/project/09-create-public-routes.sh

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

  log "INFO" "Inicializando entorno para crear rutas públicas"
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
  local target_dir="src/interfaces/http/public"

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
generate_public_routes_content() {
  cat <<'EOF'
import express from 'express';

const router = express.Router();

router.get('/info', (req, res) => {
  res.json({ app: 'Hexagonizer', version: '1.0.0', description: 'Información pública' });
});

export default router;
EOF
}

# ========================
# FILE CREATION
# ========================
create_public_routes_file() {
  local file_path="src/interfaces/http/public/public.routes.js"
  local content

  log "INFO" "Generando contenido para el archivo de rutas públicas"
  content=$(generate_public_routes_content)

  log "INFO" "Creando archivo: $file_path"

  if write_file_with_confirm "$file_path" "$content"; then
    log "SUCCESS" "Archivo de rutas públicas creado correctamente: $file_path"
  else
    log "ERROR" "Error al crear el archivo de rutas públicas: $file_path"
    return 1
  fi
}

# ========================
# MAIN FUNCTION
# ========================
main() {
  log "INFO" "Iniciando proceso de creación de rutas públicas"

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

  # Crear archivo de rutas públicas
  if ! create_public_routes_file; then
    log "ERROR" "Error al crear archivo de rutas públicas"
    exit 1
  fi

  log "SUCCESS" "Proceso de creación de rutas públicas completado exitosamente"
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
