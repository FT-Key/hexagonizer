#!/bin/bash
# init-project.sh
# shellcheck disable=SC1091 disable=SC2034

set -e

source "$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)/../generator/common/logging.sh"

declare -A MODULE_DESCRIPTIONS=(
  ["01-check-node-and-npm.sh"]="Configurando proyecto Node.js"
  ["03-create-folders.sh"]="Creando estructura de directorios"
  ["04-create-base-files.sh"]="Creando archivos base del proyecto"
  ["05-create-index.sh"]="Creando punto de entrada"
  ["06-create-server.sh"]="Creando servidor Express"
  ["07-create-html.sh"]="Creando página de inicio"
  ["08-create-health-routes.sh"]="Creando rutas de health"
  ["09-create-public-routes.sh"]="Creando rutas públicas"
  ["10-create-router-wrapper.sh"]="Creando wrapper de router"
  ["11-generate-base-middlewares.sh"]="Creando middlewares"
  ["12-generate-query-utils.sh"]="Generando utilidades de consulta"
  ["13-generate-database-config.sh"]="Configurando base de datos"
  ["14-setup-docker.sh"]="Configurando Docker"
)

setup_environment() {
  SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
  PROJECT_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"
  export SCRIPT_DIR PROJECT_ROOT
}

parse_and_setup_args() {
  INIT_ARGS=("$@")
  export INIT_ARGS
  source "$PROJECT_ROOT/generator/project/00-parse-args.sh"
}

setup_middlewares_config() {
  source "$PROJECT_ROOT/generator/common/confirm-action.sh"

  if [[ "$AUTO_YES" == true ]]; then
    CREATE_MIDDLEWARES=true
    SETUP_DOCKER=true
  else
    read -r -p "¿Deseas agregar middlewares base (auth, role, error, etc)? (y/n): " middleware_response
    middleware_response=${middleware_response,,}
    CREATE_MIDDLEWARES=false
    [[ "$middleware_response" =~ ^(y|yes|s|si)$ ]] && CREATE_MIDDLEWARES=true

    read -r -p "¿Deseas agregar configuración Docker al proyecto? (y/n): " docker_response
    docker_response=${docker_response,,}
    SETUP_DOCKER=false
    [[ "$docker_response" =~ ^(y|yes|s|si)$ ]] && SETUP_DOCKER=true
  fi

  export CREATE_MIDDLEWARES SETUP_DOCKER
}

execute_project_modules() {
  for script in "$PROJECT_ROOT/generator/project"/[0-9][0-9]-*.sh; do
    [[ -f "$script" ]] || continue
    local name
    name=$(basename "$script")
    [[ "$name" == "00-parse-args.sh" ]] && continue

    local desc="${MODULE_DESCRIPTIONS[$name]:-$name}"
    log "INFO" "$desc"
    bash "$script" || { log "ERROR" "Error: $desc"; return 1; }
  done
}

show_help() {
  cat <<EOF
Uso: $0 [OPCIONES]

OPCIONES:
  -y, --yes    Modo automático, responde 'sí' a todas las preguntas
  -h, --help   Muestra esta ayuda
EOF
}

main() {
  for arg in "$@"; do
    if [[ "$arg" == "-h" || "$arg" == "--help" ]]; then
      show_help
      return 0
    fi
  done

  log "INFO" "=== INICIANDO GENERACIÓN DE PROYECTO ==="

  setup_environment
  parse_and_setup_args "$@"
  setup_middlewares_config
  execute_project_modules || return 1

  log "SUCCESS" "=== PROYECTO GENERADO CON ÉXITO ==="
}

if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
  main "$@"
fi

if [[ "${BASH_SOURCE[0]}" != "${0}" && $# -gt 0 ]]; then
  main "$@"
fi
