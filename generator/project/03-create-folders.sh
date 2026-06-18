#!/bin/bash
# generator/project/03-create-folders.sh

set -e

source "$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)/../common/logging.sh"

# ========================
# PROJECT STRUCTURE CONFIGURATION
# ========================
# Estructura de directorios del proyecto hexagonal
readonly PROJECT_DIRECTORIES=(
  "src/config"
  "src/domain"
  "src/infrastructure"
  "src/infrastructure/database"
  "src/interfaces/http/health"
  "src/interfaces/http/public"
  "src/interfaces/http/middlewares"
  "src/application"
  "src/utils"
  "src/public"
  "tests/application"
  "tests/interfaces/http/middlewares"
)

# Directorios opcionales (se crean solo si se necesitan)
readonly OPTIONAL_DIRECTORIES=(
  "src/domain/entities"
  "src/domain/repositories"
  "src/domain/services"
  "src/application/use-cases"
  "src/infrastructure/repositories"
  "tests/domain"
  "tests/infrastructure"
  "docs"
  "scripts"
)

# ========================
# DIRECTORY CREATION FUNCTIONS
# ========================
create_base_directories() {
  for dir in "${PROJECT_DIRECTORIES[@]}"; do
    mkdir -p "$dir"
  done
  log "SUCCESS" "Directorios base creados"
}

create_optional_directories() {
  [[ "$CREATE_OPTIONAL_DIRS" != true ]] && return 0
  for dir in "${OPTIONAL_DIRECTORIES[@]}"; do
    mkdir -p "$dir"
  done
  log "SUCCESS" "Directorios opcionales creados"
}

create_gitkeep_files() {
  local empty_dirs=( "src/public" "src/domain" "src/infrastructure/database" "tests/application" "tests/interfaces/http/middlewares" )
  for dir in "${empty_dirs[@]}"; do
    [[ -d "$dir" && ! -f "$dir/.gitkeep" ]] && touch "$dir/.gitkeep"
  done
}

show_help() {
  cat <<EOF
Uso: $0 [OPCIONES]

OPCIONES:
  --optional       Crear también directorios opcionales
  -h, --help       Muestra esta ayuda

DESCRIPCIÓN:
  Este script crea la estructura de directorios base para un proyecto
  con arquitectura hexagonal.

DIRECTORIOS BASE (${#PROJECT_DIRECTORIES[@]}):
$(printf "  %s\n" "${PROJECT_DIRECTORIES[@]}")

DIRECTORIOS OPCIONALES (${#OPTIONAL_DIRECTORIES[@]}):
$(printf "  %s\n" "${OPTIONAL_DIRECTORIES[@]}")

VARIABLES DE ENTORNO:
  CREATE_OPTIONAL_DIRS=true    Crear directorios opcionales

EJEMPLO:
  $0                    # Solo directorios base
  $0 --optional         # Base + opcionales
  CREATE_OPTIONAL_DIRS=true $0  # Base + opcionales
EOF
}

# ========================
# MAIN FUNCTION
# ========================
main() {
  for arg in "$@"; do
    case "$arg" in -h|--help) show_help; return 0;; --optional) export CREATE_OPTIONAL_DIRS=true;; esac
  done

  create_base_directories
  create_optional_directories
  create_gitkeep_files
}

# ========================
# EXECUTION LOGIC
# ========================
# Si se llama directamente con bash
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
  main "$@"
fi

# Si se hace source y hay condiciones específicas
if [[ "${BASH_SOURCE[0]}" != "${0}" && (-n "${CREATE_MIDDLEWARES:-}" || $# -gt 0) ]]; then
  main "$@"
fi
