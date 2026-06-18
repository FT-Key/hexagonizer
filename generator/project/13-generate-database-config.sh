#!/bin/bash
# hexagonizer/project/13-generate-database-config.sh
# shellcheck disable=SC1091

set -e

source "$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)/../common/logging.sh"

# ========================
# INITIALIZATION
# ========================
init_environment() {
  PROJECT_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
  local confirm_script="$PROJECT_ROOT/generator/common/confirm-action.sh"
  if [[ -f "$confirm_script" ]]; then
    source "$confirm_script"
  else
    log "ERROR" "confirm-action.sh not found"
    return 1
  fi
}

# ========================
# UTILITY FUNCTIONS
# ========================
write_file_with_confirm() {
  local filepath="$1"
  local content="$2"
  if [[ -f "$filepath" ]]; then
    if [[ "$AUTO_YES" == true ]]; then
      echo "$content" >"$filepath"
    else
      confirm_action "File $(basename "$filepath") already exists. Overwrite? (y/n): " || return 1
      echo "$content" >"$filepath"
    fi
  else
    echo "$content" >"$filepath"
  fi
}

# ========================
# DIRECTORY CREATION
# ========================
create_directories() {
  mkdir -p "src/config" "src/infrastructure/database"
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
create_database_files() {
  write_file_with_confirm "src/config/database.js" "$(generate_database_config_content)"
  write_file_with_confirm "src/infrastructure/database/database.js" "$(generate_database_connection_content)"
  log "SUCCESS" "Database files created"
}

# ========================
# MAIN FUNCTION
# ========================
main() {
  init_environment || exit 1
  create_directories
  create_database_files
}

# ========================
# EXECUTION LOGIC
# ========================
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
  main "$@"
fi
