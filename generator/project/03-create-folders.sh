#!/bin/bash
# 02-create-folders.sh

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
create_directory_safe() {
  local dir_path="$1"
  local is_optional="${2:-false}"

  if [[ -d "$dir_path" ]]; then
    log "INFO" "Directorio '$dir_path' ya existe, omitiendo"
    return 0
  fi

  if mkdir -p "$dir_path" 2>/dev/null; then
    log "SUCCESS" "Directorio '$dir_path' creado correctamente"
    return 0
  else
    if [[ "$is_optional" == true ]]; then
      log "WARN" "No se pudo crear directorio opcional '$dir_path'"
      return 0
    else
      log "ERROR" "Error creando directorio requerido '$dir_path'"
      return 1
    fi
  fi
}

create_base_directories() {
  log "INFO" "Creando estructura de directorios base del proyecto"

  local created_count=0
  local existing_count=0
  local error_count=0

  for dir in "${PROJECT_DIRECTORIES[@]}"; do
    if [[ -d "$dir" ]]; then
      ((existing_count++))
      log "INFO" "Directorio '$dir' ya existe"
    else
      if create_directory_safe "$dir"; then
        ((created_count++))
      else
        ((error_count++))
      fi
    fi
  done

  if [[ $error_count -gt 0 ]]; then
    log "ERROR" "Error creando $error_count directorios base"
    return 1
  fi

  log "SUCCESS" "Directorios base procesados (creados: $created_count, existentes: $existing_count)"
  return 0
}

create_optional_directories() {
  # Solo crear directorios opcionales si se especifica explícitamente
  if [[ "$CREATE_OPTIONAL_DIRS" != true ]]; then
    log "INFO" "Omitiendo creación de directorios opcionales (CREATE_OPTIONAL_DIRS != true)"
    return 0
  fi

  log "INFO" "Creando directorios opcionales del proyecto"

  local created_count=0
  local existing_count=0

  for dir in "${OPTIONAL_DIRECTORIES[@]}"; do
    if [[ -d "$dir" ]]; then
      ((existing_count++))
      log "INFO" "Directorio opcional '$dir' ya existe"
    else
      if create_directory_safe "$dir" true; then
        ((created_count++))
      fi
    fi
  done

  log "SUCCESS" "Directorios opcionales procesados (creados: $created_count, existentes: $existing_count)"
  return 0
}

create_gitkeep_files() {
  log "INFO" "Creando archivos .gitkeep para directorios vacíos"

  local gitkeep_count=0
  local skipped_count=0

  # Solo crear .gitkeep en directorios que estarán vacíos inicialmente
  local empty_dirs=(
    "src/public"
    "src/domain"
    "src/infrastructure/database"
    "tests/application"
    "tests/interfaces/http/middlewares"
  )

  for dir in "${empty_dirs[@]}"; do
    if [[ -d "$dir" ]]; then
      local gitkeep_file="$dir/.gitkeep"
      if [[ ! -f "$gitkeep_file" ]]; then
        if touch "$gitkeep_file" 2>/dev/null; then
          log "SUCCESS" "Archivo .gitkeep creado en '$dir'"
          ((gitkeep_count++))
        else
          log "WARN" "No se pudo crear .gitkeep en '$dir'"
        fi
      else
        log "INFO" ".gitkeep ya existe en '$dir'"
        ((skipped_count++))
      fi
    fi
  done

  log "SUCCESS" "Archivos .gitkeep procesados (creados: $gitkeep_count, omitidos: $skipped_count)"
  return 0
}

validate_project_structure() {
  log "INFO" "Validando estructura de proyecto creada"

  local missing_dirs=()

  for dir in "${PROJECT_DIRECTORIES[@]}"; do
    if [[ ! -d "$dir" ]]; then
      missing_dirs+=("$dir")
    fi
  done

  if [[ ${#missing_dirs[@]} -gt 0 ]]; then
    log "ERROR" "Directorios faltantes después de la creación:"
    for missing_dir in "${missing_dirs[@]}"; do
      log "ERROR" "  - $missing_dir"
    done
    return 1
  fi

  log "SUCCESS" "Estructura de proyecto validada correctamente"
  return 0
}

show_project_tree() {
  log "INFO" "Estructura de directorios creada:"

  # Mostrar estructura usando tree si está disponible, sino usar find
  if command -v tree &>/dev/null; then
    tree -d -L 4 src/ tests/ 2>/dev/null || {
      log "INFO" "Usando listado alternativo (tree falló)"
      show_directory_structure_alternative
    }
  else
    show_directory_structure_alternative
  fi
}

show_directory_structure_alternative() {
  log "INFO" "Directorios principales creados:"
  find src tests -type d 2>/dev/null | head -20 | while read -r dir; do
    local level
    level=$(echo "$dir" | tr -cd '/' | wc -c)
    local indent
    indent=$(printf "%*s" $((level * 2)) "")
    log "INFO" "  $indent└── $(basename "$dir")"
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
  log "INFO" "=== CREACIÓN DE ESTRUCTURA DE DIRECTORIOS ==="

  # Procesar argumentos
  for arg in "$@"; do
    case "$arg" in
    -h | --help)
      show_help
      return 0
      ;;
    --optional)
      export CREATE_OPTIONAL_DIRS=true
      ;;
    esac
  done

  local start_time
  start_time=$(date +%s)

  # Ejecutar creación de directorios
  create_base_directories || {
    log "ERROR" "Error creando directorios base"
    return 1
  }

  create_optional_directories || {
    log "WARN" "Advertencias creando directorios opcionales (no crítico)"
  }

  create_gitkeep_files || {
    log "WARN" "Advertencias creando archivos .gitkeep (no crítico)"
  }

  validate_project_structure || {
    log "ERROR" "Validación de estructura falló"
    return 1
  }

  show_project_tree

  local end_time
  end_time=$(date +%s)
  local duration=$((end_time - start_time))

  log "SUCCESS" "=== ESTRUCTURA DE DIRECTORIOS COMPLETADA ==="
  log "SUCCESS" "Tiempo total: ${duration}s"
  log "INFO" "Total de directorios base: ${#PROJECT_DIRECTORIES[@]}"

  if [[ "$CREATE_OPTIONAL_DIRS" == true ]]; then
    log "INFO" "Total de directorios opcionales: ${#OPTIONAL_DIRECTORIES[@]}"
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
if [[ "${BASH_SOURCE[0]}" != "${0}" && (-n "${CREATE_MIDDLEWARES:-}" || $# -gt 0) ]]; then
  main "$@"
fi
