#!/bin/bash
# hexagonizer/project/13-generate-database-config.sh
# shellcheck disable=SC1091

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

  log "INFO" "Inicializando entorno para generar configuración de base de datos"
  log "INFO" "Directorio del script: $SCRIPT_DIR"
  log "INFO" "Directorio raíz del proyecto: $PROJECT_ROOT"

  # Source del archivo de confirmación
  local confirm_script="$PROJECT_ROOT/generator/common/confirm-action.sh"
  if [[ -f "$confirm_script" ]]; then
    source "$confirm_script"
    log "SUCCESS" "Archivo confirm-action.sh cargado correctamente"
  else
    log "ERROR" "No se encontró el archivo confirm-action.sh: $confirm_script"
    return 1
  fi
}

# ========================
# UTILITY FUNCTIONS
# ========================
write_file_with_confirm() {
  local filepath="$1"
  local content="$2"
  local filename
  filename=$(basename "$filepath")

  log "INFO" "Procesando archivo: $filepath"

  if [[ -f "$filepath" ]]; then
    if [[ "$AUTO_YES" == true ]]; then
      log "WARN" "El archivo $filename ya existe. Sobrescribiendo por opción -y"
      if echo "$content" >"$filepath"; then
        log "SUCCESS" "Archivo $filename sobrescrito correctamente"
      else
        log "ERROR" "Error al sobrescribir $filename"
        return 1
      fi
    else
      if confirm_action "⚠️  El archivo $filepath ya existe. ¿Desea sobrescribirlo? (y/n): "; then
        if echo "$content" >"$filepath"; then
          log "SUCCESS" "Archivo $filename sobrescrito correctamente"
        else
          log "ERROR" "Error al sobrescribir $filename"
          return 1
        fi
      else
        log "WARN" "No se sobrescribió $filename"
        return 1
      fi
    fi
  else
    if echo "$content" >"$filepath"; then
      log "SUCCESS" "Archivo $filename creado correctamente"
    else
      log "ERROR" "Error al crear $filename"
      return 1
    fi
  fi
}

# ========================
# DIRECTORY CREATION
# ========================
create_directories() {
  local config_dir="src/config"
  local database_dir="src/infrastructure/database"

  log "INFO" "Creando directorios necesarios"

  if mkdir -p "$config_dir"; then
    log "SUCCESS" "Directorio creado: $config_dir"
  else
    log "ERROR" "Error al crear directorio: $config_dir"
    return 1
  fi

  if mkdir -p "$database_dir"; then
    log "SUCCESS" "Directorio creado: $database_dir"
  else
    log "ERROR" "Error al crear directorio: $database_dir"
    return 1
  fi
}

# ========================
# FILE CONTENT GENERATORS
# ========================
generate_database_config_content() {
  cat <<'EOF'
// src/config/database.js

/**
 * Archivo de configuración para base de datos.
 * Agregá aquí las variables de entorno y configuración necesarias.
 */

export const databaseConfig = {
  // Agrega aquí tus variables de configuración, por ejemplo:
  // MONGO_URI: process.env.MONGO_URI || 'mongodb://localhost:27017/miapp',
};
EOF
}

generate_database_connection_content() {
  cat <<'EOF'
// src/infrastructure/database/database.js

/**
 * Implementa la conexión a la base de datos aquí.
 * Ejemplo: usando Mongoose, Sequelize, Prisma, etc.
 */

export async function connectToDatabase() {
  // Implementar la conexión a la base de datos.
}
EOF
}

# ========================
# FILE CREATION
# ========================
create_database_config_file() {
  local file_path="src/config/database.js"
  local content

  log "INFO" "Generando contenido para configuración de base de datos"
  content=$(generate_database_config_content)

  write_file_with_confirm "$file_path" "$content"
}

create_database_connection_file() {
  local file_path="src/infrastructure/database/database.js"
  local content

  log "INFO" "Generando contenido para conexión de base de datos"
  content=$(generate_database_connection_content)

  write_file_with_confirm "$file_path" "$content"
}

# ========================
# DATABASE FILES ORCHESTRATION
# ========================
create_all_database_files() {
  log "INFO" "Iniciando creación de archivos de configuración de base de datos"

  local failed=0

  # Crear archivo de configuración
  if ! create_database_config_file; then
    ((failed++))
  fi

  # Crear archivo de conexión
  if ! create_database_connection_file; then
    ((failed++))
  fi

  if [ $failed -gt 0 ]; then
    log "ERROR" "$failed archivos de base de datos fallaron al crearse"
    return 1
  else
    log "SUCCESS" "Todos los archivos de configuración de base de datos fueron procesados correctamente"
    return 0
  fi
}

# ========================
# MAIN FUNCTION
# ========================
main() {
  log "INFO" "Iniciando proceso de generación de configuración de base de datos"

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

  # Crear todos los archivos de base de datos
  if ! create_all_database_files; then
    log "ERROR" "Error al crear archivos de configuración de base de datos"
    exit 1
  fi

  log "SUCCESS" "Proceso de generación de configuración de base de datos completado exitosamente"
  log "SUCCESS" "Archivos de configuración de base de datos creados (vacíos para implementar)"
}

# ========================
# EXECUTION LOGIC
# ========================
# Si se llama directamente con bash
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
  main "$@"
fi

# Si se hace source y hay condiciones específicas
if [[ "${BASH_SOURCE[0]}" != "${0}" && (-n "${CREATE_DATABASE_CONFIG:-}" || $# -gt 0) ]]; then
  main "$@"
fi
