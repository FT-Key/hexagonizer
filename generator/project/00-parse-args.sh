#!/bin/bash
# generator/project/00-parse-args.sh

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
# PARSE ARGUMENTS FUNCTION
# ========================
parse_arguments() {
  log "INFO" "Iniciando parseo de argumentos"

  # Usar INIT_ARGS si está disponible, sino usar argumentos pasados
  local args_to_parse=("$@")
  if [[ -n "${INIT_ARGS:-}" ]]; then
    args_to_parse=("${INIT_ARGS[@]}")
    log "INFO" "Usando INIT_ARGS con ${#INIT_ARGS[@]} argumentos"
  else
    log "INFO" "Usando argumentos directos: $*"
  fi

  # Procesar argumentos para detectar -y / --yes
  AUTO_YES=false
  for arg in "${args_to_parse[@]}"; do
    case "$arg" in
    -y | --yes)
      AUTO_YES=true
      log "INFO" "Modo automático activado (-y/--yes detectado)"
      break
      ;;
    -h | --help)
      show_help
      return 0
      ;;
    esac
  done

  export AUTO_YES
  log "SUCCESS" "Argumentos parseados correctamente (AUTO_YES=$AUTO_YES)"
}

# ========================
# HELP FUNCTION
# ========================
show_help() {
  cat <<EOF
Uso: $0 [OPCIONES]

OPCIONES:
  -y, --yes    Modo automático, responde 'sí' a todas las preguntas
  -h, --help   Muestra esta ayuda

DESCRIPCIÓN:
  Este script parsea los argumentos del proyecto y configura las variables
  de entorno necesarias para la generación automática.
EOF
}

# ========================
# MAIN FUNCTION
# ========================
main() {
  log "INFO" "Ejecutando parse-args como script principal"
  parse_arguments "$@"

  if [[ "$AUTO_YES" == true ]]; then
    log "SUCCESS" "Configuración completada en modo automático"
  else
    log "SUCCESS" "Configuración completada en modo interactivo"
  fi
}

# ========================
# EXECUTION LOGIC
# ========================
# Si se llama directamente con bash
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
  main "$@"
fi

# Si se hace source y hay argumentos o INIT_ARGS
if [[ "${BASH_SOURCE[0]}" != "${0}" && (-n "${INIT_ARGS:-}" || $# -gt 0) ]]; then
  parse_arguments "$@"
fi
