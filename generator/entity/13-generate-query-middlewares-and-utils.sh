#!/bin/bash
# generator/entity/13-generate-query-middlewares-and-utils.sh
# shellcheck disable=SC1091,SC2154
set -e

# ===================================
# Colores para output
# ===================================
if [[ -z "${RED:-}" ]]; then
  readonly RED='\033[0;31m'
  readonly GREEN='\033[0;32m'
  readonly YELLOW='\033[1;33m'
  readonly BLUE='\033[0;34m'
  readonly NC='\033[0m' # No Color
fi

# ===================================
# Logging
# ===================================
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

# ===================================
# Main
# ===================================
main() {
  validate_required_variables || exit 1
  init_project_variables
  generate_query_components
}

validate_required_variables() {
  if [[ -z "${entity:-}" ]]; then
    log "ERROR" "La variable 'entity' es requerida"
    echo "Uso: $0 <entity>"
    echo "Ejemplo: $0 user"
    return 1
  fi
}

init_project_variables() {
  if [[ -z "${PROJECT_ROOT:-}" ]]; then
    PROJECT_ROOT="$(cd "$(dirname "$(dirname "$(dirname "${BASH_SOURCE[0]}")")")" && pwd)"
  fi

  readonly COMMON_DIR="$PROJECT_ROOT/generator/common"
  readonly MIDDLEWARES_SCRIPT="$COMMON_DIR/generate-query-middlewares.sh"
  readonly UTILS_SCRIPT="$COMMON_DIR/generate-query-utils.sh"
}

validate_common_scripts() {
  local missing_scripts=()

  if [[ ! -f "$MIDDLEWARES_SCRIPT" ]]; then
    missing_scripts+=("$MIDDLEWARES_SCRIPT")
  fi

  if [[ ! -f "$UTILS_SCRIPT" ]]; then
    missing_scripts+=("$UTILS_SCRIPT")
  fi

  if [[ ${#missing_scripts[@]} -gt 0 ]]; then
    log "ERROR" "No se encontraron los siguientes scripts necesarios:"
    printf "  - %s\n" "${missing_scripts[@]}"
    return 1
  fi
}

generate_query_components() {
  log "INFO" "Generando middlewares y utils de query para la entidad: $entity"

  validate_common_scripts || exit 1

  log "INFO" "Cargando script de middlewares..."
  source "$MIDDLEWARES_SCRIPT" || {
    log "ERROR" "Error al cargar el script de middlewares"
    exit 1
  }

  log "INFO" "Cargando script de utils..."
  source "$UTILS_SCRIPT" || {
    log "ERROR" "Error al cargar el script de utils"
    exit 1
  }

  log "SUCCESS" "Middlewares y utils de query generados correctamente"
}

show_debug_info() {
  if [[ "${DEBUG:-}" == "true" ]]; then
    cat <<EOF
🐛 Información de debug:
  - Entity: ${entity:-"No definida"}
  - PROJECT_ROOT: ${PROJECT_ROOT:-"No definida"}
  - MIDDLEWARES_SCRIPT: ${MIDDLEWARES_SCRIPT:-"No definida"}
  - UTILS_SCRIPT: ${UTILS_SCRIPT:-"No definida"}
EOF
  fi
}

parse_arguments() {
  while [[ $# -gt 0 ]]; do
    case $1 in
    --debug)
      DEBUG=true
      shift
      ;;
    -h | --help)
      show_help
      exit 0
      ;;
    *)
      if [[ -z "${entity:-}" ]]; then
        entity="$1"
      fi
      shift
      ;;
    esac
  done
}

show_help() {
  cat <<EOF
Uso: $0 [OPCIONES] <entity>

Genera middlewares y utils de query para una entidad específica.

Argumentos:
  entity          Nombre de la entidad (ej: user, product)

Opciones:
  --debug         Mostrar información de debug
  -h, --help      Mostrar esta ayuda

Variables de entorno:
  PROJECT_ROOT    Ruta raíz del proyecto (se detecta automáticamente)

Ejemplo:
  $0 user
  $0 --debug product

EOF
}

# ===================================
# Ejecución
# ===================================
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
  parse_arguments "$@"
  show_debug_info
  main "$@"
fi

if [[ -n "${entity:-}" ]]; then
  main "$@"
fi
