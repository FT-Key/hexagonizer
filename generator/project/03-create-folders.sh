#!/bin/bash
# generator/project/03-create-folders.sh

set -e

source "$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)/../common/logging.sh"

# ========================
# PROJECT STRUCTURE CONFIGURATION
# ========================
# Hexagonal project directory structure
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
  log "SUCCESS" "Base directories created"
}

create_optional_directories() {
  [[ "$CREATE_OPTIONAL_DIRS" != true ]] && return 0
  for dir in "${OPTIONAL_DIRECTORIES[@]}"; do
    mkdir -p "$dir"
  done
  log "SUCCESS" "Optional directories created"
}

create_gitkeep_files() {
  local empty_dirs=( "src/public" "src/domain" "src/infrastructure/database" "tests/application" "tests/interfaces/http/middlewares" )
  for dir in "${empty_dirs[@]}"; do
    [[ -d "$dir" && ! -f "$dir/.gitkeep" ]] && touch "$dir/.gitkeep"
  done
}

show_help() {
  cat <<EOF
Usage: $0 [OPTIONS]

OPTIONS:
  --optional       Also create optional directories
  -h, --help       Show this help

DESCRIPTION:
  This script creates the base directory structure for a project
  with hexagonal architecture.

BASE DIRECTORIES (${#PROJECT_DIRECTORIES[@]}):
$(printf "  %s\n" "${PROJECT_DIRECTORIES[@]}")

OPTIONAL DIRECTORIES (${#OPTIONAL_DIRECTORIES[@]}):
$(printf "  %s\n" "${OPTIONAL_DIRECTORIES[@]}")

ENVIRONMENT VARIABLES:
  CREATE_OPTIONAL_DIRS=true    Create optional directories

EXAMPLE:
  $0                    # Base directories only
  $0 --optional         # Base + optional
  CREATE_OPTIONAL_DIRS=true $0  # Base + optional
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
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
  main "$@"
fi
