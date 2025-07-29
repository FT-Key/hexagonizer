#!/bin/bash
# hexagonizer/common/generate-query-utils.sh

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
# CONFIGURATION
# ========================
readonly UTILS_PATH="src/utils"
readonly QUERY_UTILS_FILE="$UTILS_PATH/query-utils.js"

# Aceptar cualquiera de las dos variables para confirmación automática
readonly AUTO_CONFIRM="${AUTO_CONFIRM:-${AUTO_YES:-false}}"

# ========================
# UTILITY FUNCTIONS
# ========================

# Función para solicitar confirmación al usuario
confirm_action() {
  local prompt="$1"

  if [[ "$AUTO_CONFIRM" == "true" ]]; then
    log "INFO" "Auto-confirmación activada, continuando..."
    return 0
  fi

  read -rp "$prompt [y/n]: " response
  case "$response" in
  [yY][eE][sS] | [yY])
    return 0
    ;;
  *)
    return 1
    ;;
  esac
}

# Función para verificar si un directorio existe
directory_exists() {
  [[ -d "$1" ]]
}

# Función para verificar si un archivo existe
file_exists() {
  [[ -f "$1" ]]
}

# ========================
# CONTENT GENERATOR
# ========================

# Generar contenido del archivo query-utils.js
generate_query_utils_content() {
  cat <<'EOF'
// src/utils/query-utils.js

/**
 * Aplica filtros exactos (case-insensitive para strings).
 * @param {Array<Object>} items
 * @param {Object} filters
 * @returns {Array<Object>}
 */
export function applyFilters(items, filters = {}) {
  return items.filter(item => {
    return Object.entries(filters).every(([key, value]) => {
      const itemVal = item[key];
      if (typeof itemVal === 'string' && typeof value === 'string') {
        return itemVal.toLowerCase() === value.toLowerCase();
      }
      if (typeof itemVal === 'boolean') {
        return itemVal === (value === 'true' || value === true);
      }
      return itemVal === value;
    });
  });
}

/**
 * Aplica búsqueda por texto libre en los campos indicados.
 * @param {Array<Object>} items
 * @param {{ query: string, fields: string[] }} search
 * @returns {Array<Object>}
 */
export function applySearch(items, search = null) {
  if (!search || !search.query || !Array.isArray(search.fields)) return items;

  const q = search.query.toLowerCase();

  return items.filter(item => {
    return search.fields.some(field => {
      const val = item[field];
      return typeof val === 'string' && val.toLowerCase().includes(q);
    });
  });
}

/**
 * Aplica ordenamiento sobre un campo específico.
 * @param {Array<Object>} items
 * @param {{ sortBy: string, order: 'asc' | 'desc' }} sort
 * @returns {Array<Object>}
 */
export function applySort(items, sort = null) {
  if (!sort || !sort.sortBy) return items;

  const { sortBy, order = 'asc' } = sort;

  return [...items].sort((a, b) => {
    const aVal = a[sortBy];
    const bVal = b[sortBy];

    if (aVal == null && bVal != null) return order === 'asc' ? -1 : 1;
    if (aVal != null && bVal == null) return order === 'asc' ? 1 : -1;
    if (aVal == null && bVal == null) return 0;

    if (typeof aVal === 'string' && typeof bVal === 'string') {
      return order === 'asc' ? aVal.localeCompare(bVal) : bVal.localeCompare(aVal);
    }

    return order === 'asc'
      ? (aVal < bVal ? -1 : aVal > bVal ? 1 : 0)
      : (aVal > bVal ? -1 : aVal < bVal ? 1 : 0);
  });
}

/**
 * Aplica paginación sobre un array.
 * @param {Array<Object>} items
 * @param {{ limit?: number, offset?: number }} pagination
 * @returns {Array<Object>}
 */
export function applyPagination(items, pagination = null) {
  if (!pagination) return items;

  const offset = pagination.offset ?? 0;
  const limit = pagination.limit ?? items.length;

  return items.slice(offset, offset + limit);
}
EOF
}

# ========================
# FILE OPERATIONS
# ========================

# Crear directorio utils si no existe
create_utils_directory() {
  log "INFO" "Verificando directorio utils..."

  if ! directory_exists "$UTILS_PATH"; then
    log "INFO" "Creando directorio $UTILS_PATH..."
    if mkdir -p "$UTILS_PATH"; then
      log "SUCCESS" "Directorio $UTILS_PATH creado"
    else
      log "ERROR" "Error creando directorio $UTILS_PATH"
      return 1
    fi
  else
    log "INFO" "Directorio $UTILS_PATH ya existe"
  fi
}

# Crear archivo query-utils.js
create_query_utils_file() {
  local content
  content=$(generate_query_utils_content)

  if echo "$content" >"$QUERY_UTILS_FILE"; then
    log "SUCCESS" "query-utils.js creado correctamente"
    return 0
  else
    log "ERROR" "Error creando query-utils.js"
    return 1
  fi
}

# Manejar archivo existente
handle_existing_file() {
  log "WARN" "query-utils.js ya existe"

  if confirm_action "¿Deseas sobrescribirlo?"; then
    log "INFO" "Sobrescribiendo query-utils.js..."
    if create_query_utils_file; then
      log "SUCCESS" "query-utils.js sobrescrito exitosamente"
      return 0
    else
      return 1
    fi
  else
    log "INFO" "No se sobrescribió query-utils.js"
    return 1
  fi
}

# Crear archivo nuevo
handle_new_file() {
  log "INFO" "Creando nuevo archivo query-utils.js..."
  if create_query_utils_file; then
    return 0
  else
    return 1
  fi
}

# ========================
# MAIN FUNCTION
# ========================
main() {
  log "INFO" "Iniciando generación de query-utils..."

  # Crear directorio si no existe
  if ! create_utils_directory; then
    log "ERROR" "Error en la creación del directorio"
    return 1
  fi

  # Verificar si el archivo existe y manejarlo apropiadamente
  if file_exists "$QUERY_UTILS_FILE"; then
    if ! handle_existing_file; then
      log "INFO" "Operación cancelada o falló"
      return 0
    fi
  else
    if ! handle_new_file; then
      log "ERROR" "Error creando el archivo"
      return 1
    fi
  fi

  log "SUCCESS" "Generación de query-utils completada exitosamente"
}

# ========================
# EXECUTION LOGIC
# ========================
# Si se llama directamente con bash
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
  main "$@"
fi

# Si se hace source y hay condiciones específicas
if [[ "${BASH_SOURCE[0]}" != "${0}" && (-n "${CREATE_QUERY_UTILS:-}" || $# -gt 0) ]]; then
  main "$@"
fi
