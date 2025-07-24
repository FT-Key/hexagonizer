#!/bin/bash
# hexagonizer/project/08-generate-database-config.sh
# shellcheck disable=SC1091

source ../hexagonizer/common/confirm-action.sh

write_file_with_confirm() {
  local filepath=$1
  local content=$2

  if [[ -f "$filepath" ]]; then
    if [[ "$AUTO_YES" == true ]]; then
      echo "⚠️  El archivo $filepath ya existe. Sobrescribiendo por opción -y."
      echo "$content" >"$filepath"
    else
      if confirm_action "⚠️  El archivo $filepath ya existe. ¿Desea sobrescribirlo? (y/n): "; then
        echo "$content" >"$filepath"
      else
        echo "❌ No se sobrescribió $filepath"
        return 1
      fi
    fi
  else
    echo "$content" >"$filepath"
  fi
}

mkdir -p src/config
mkdir -p src/infrastructure/database

write_file_with_confirm "src/config/database.js" "$(
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
)"

write_file_with_confirm "src/infrastructure/database/database.js" "$(
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
)"

echo "✅ Archivos de configuración de base de datos creados (vacíos para implementar)."
