#!/bin/bash
# init-project.sh
# shellcheck disable=SC1091
# shellcheck disable=SC2034

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
# SETUP FUNCTIONS
# ========================
setup_environment() {
  log "INFO" "Configurando entorno del proyecto"

  # Obtener la ruta absoluta del directorio del script
  SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
  PROJECT_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"

  log "INFO" "SCRIPT_DIR: $SCRIPT_DIR"
  log "INFO" "PROJECT_ROOT: $PROJECT_ROOT"

  export SCRIPT_DIR PROJECT_ROOT
}

parse_and_setup_args() {
  log "INFO" "Procesando argumentos iniciales"

  # Guardar args para pasar a módulos
  INIT_ARGS=("$@")
  export INIT_ARGS

  log "INFO" "Argumentos guardados: ${INIT_ARGS[*]}"

  # Ejecutar primer módulo para parsear args
  log "INFO" "Ejecutando módulo de parseo de argumentos"
  if [[ -f "$PROJECT_ROOT/generator/project/00-parse-args.sh" ]]; then
    source "$PROJECT_ROOT/generator/project/00-parse-args.sh"
    log "SUCCESS" "Módulo de parseo ejecutado correctamente"
  else
    log "ERROR" "No se encontró el módulo 00-parse-args.sh"
    return 1
  fi
}

setup_middlewares_config() {
  log "INFO" "Configurando middlewares del proyecto"

  # Importar función confirm_action
  if [[ -f "$PROJECT_ROOT/generator/common/confirm-action.sh" ]]; then
    source "$PROJECT_ROOT/generator/common/confirm-action.sh"
    log "INFO" "Función confirm_action importada"
  else
    log "WARN" "No se encontró confirm-action.sh, continuando sin él"
  fi

  # Preguntar si se desean crear middlewares base
  if [[ "$AUTO_YES" == true ]]; then
    CREATE_MIDDLEWARES=true
    log "INFO" "Middlewares base activados automáticamente (modo -y)"
  else
    log "INFO" "Solicitando confirmación para crear middlewares base"
    read -r -p "¿Deseas agregar middlewares base (auth, role, error, etc)? (y/n): " middleware_response
    middleware_response=${middleware_response,,}
    CREATE_MIDDLEWARES=false
    if [[ "$middleware_response" =~ ^(y|yes|s|si)$ ]]; then
      CREATE_MIDDLEWARES=true
      log "INFO" "Usuario confirmó creación de middlewares"
    else
      log "INFO" "Usuario declinó creación de middlewares"
    fi
  fi

  export CREATE_MIDDLEWARES
  log "SUCCESS" "Configuración de middlewares completada (CREATE_MIDDLEWARES=$CREATE_MIDDLEWARES)"
}

execute_project_modules() {
  log "INFO" "Iniciando ejecución de módulos del proyecto"

  local modules_executed=0
  local modules_skipped=0

  # Ejecutar el resto de módulos (excepto 00-parse-args.sh)
  for script in "$PROJECT_ROOT/generator/project"/[0-9][0-9]-*.sh; do
    if [[ -f "$script" ]]; then
      local script_name
      script_name=$(basename "$script")

      if [[ "$script" != *"00-parse-args.sh" ]]; then
        log "INFO" "Ejecutando módulo: $script_name"
        if bash "$script"; then
          log "SUCCESS" "Módulo $script_name ejecutado correctamente"
          ((modules_executed++))
        else
          log "ERROR" "Error ejecutando módulo $script_name"
          return 1
        fi
      else
        log "INFO" "Omitiendo módulo ya ejecutado: $script_name"
        ((modules_skipped++))
      fi
    fi
  done

  log "SUCCESS" "Módulos ejecutados: $modules_executed, omitidos: $modules_skipped"
}

show_help() {
  cat <<EOF
Uso: $0 [OPCIONES]

OPCIONES:
  -y, --yes    Modo automático, responde 'sí' a todas las preguntas
  -h, --help   Muestra esta ayuda

DESCRIPCIÓN:
  Este script inicializa un nuevo proyecto ejecutando todos los módulos
  de generación en el orden correcto.

EJEMPLO:
  $0                # Modo interactivo
  $0 -y            # Modo automático
  $0 --yes         # Modo automático (forma larga)
EOF
}

# ========================
# MAIN FUNCTION
# ========================
main() {
  log "INFO" "=== INICIANDO GENERACIÓN DE PROYECTO ==="

  # Verificar argumentos de ayuda
  for arg in "$@"; do
    if [[ "$arg" == "-h" || "$arg" == "--help" ]]; then
      show_help
      return 0
    fi
  done

  local start_time
  start_time=$(date +%s)

  # Ejecutar pasos de inicialización
  setup_environment || {
    log "ERROR" "Error en configuración del entorno"
    return 1
  }

  parse_and_setup_args "$@" || {
    log "ERROR" "Error en parseo de argumentos"
    return 1
  }

  setup_middlewares_config || {
    log "ERROR" "Error en configuración de middlewares"
    return 1
  }

  execute_project_modules || {
    log "ERROR" "Error ejecutando módulos del proyecto"
    return 1
  }

  local end_time
  end_time=$(date +%s)
  local duration=$((end_time - start_time))

  log "SUCCESS" "=== PROYECTO GENERADO CON ÉXITO ==="
  log "SUCCESS" "Tiempo total: ${duration}s"
  log "SUCCESS" "¡Listo para comenzar!"
}

# ========================
# EXECUTION LOGIC
# ========================
# Si se llama directamente con bash
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
  main "$@"
fi

# Si se hace source (para casos especiales de testing o debugging)
if [[ "${BASH_SOURCE[0]}" != "${0}" && $# -gt 0 ]]; then
  log "INFO" "Script ejecutado via source con argumentos"
  main "$@"
fi
