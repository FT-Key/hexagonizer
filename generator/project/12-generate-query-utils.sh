#!/bin/bash
# generator/project/12-generate-query-utils.sh

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
  PROJECT_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"

  log "INFO" "Inicializando entorno para generar query utils"
  log "INFO" "Directorio raíz del proyecto: $PROJECT_ROOT"

  # Verificar que existe el script de query utils en common
  local query_utils_script="$PROJECT_ROOT/generator/common/generate-query-utils.sh"

  if [[ -f "$query_utils_script" ]]; then
    log "SUCCESS" "Script de query utils encontrado: $query_utils_script"
    QUERY_UTILS_SCRIPT="$query_utils_script"
  else
    log "ERROR" "No se encontró el script de query utils: $query_utils_script"
    return 1
  fi
}

# ========================
# QUERY UTILS EXECUTION
# ========================
execute_query_utils_generator() {
  log "INFO" "Ejecutando generador de query utils"
  log "INFO" "Comando: bash $QUERY_UTILS_SCRIPT $*"

  if bash "$QUERY_UTILS_SCRIPT" "$@"; then
    log "SUCCESS" "Generador de query utils ejecutado correctamente"
  else
    local exit_code=$?
    log "ERROR" "Error al ejecutar el generador de query utils (código: $exit_code)"
    return $exit_code
  fi
}

# ========================
# MAIN FUNCTION
# ========================
main() {
  log "INFO" "Iniciando proceso de generación de query utils"

  # Inicializar entorno
  if ! init_environment; then
    log "ERROR" "Error en la inicialización del entorno"
    exit 1
  fi

  # Ejecutar generador de query utils
  if ! execute_query_utils_generator "$@"; then
    log "ERROR" "Error al ejecutar el generador de query utils"
    exit 1
  fi

  log "SUCCESS" "Proceso de generación de query utils completado exitosamente"
}

# ========================
# EXECUTION LOGIC
# ========================
# Si se llama directamente con bash
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
  main "$@"
fi

# Si se hace source y hay condiciones específicas
if [[ "${BASH_SOURCE[0]}" != "${0}" && (-n "${CREATE_QUERY_UTILS:-}" || $# -gt 0) ]]; then
  main "$@"
fi
