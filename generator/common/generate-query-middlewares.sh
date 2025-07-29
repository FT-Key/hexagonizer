#!/bin/bash
# hexagonizer/common/generate-query-middlewares.sh

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
readonly QUERY_MIDDLEWARE_PATH="src/interfaces/http/middlewares"

# ========================
# UTILITY FUNCTIONS
# ========================

# Función para crear archivos solo si no existen
create_file_if_not_exists() {
  local filepath="$1"
  local content="$2"
  local filename
  filename=$(basename "$filepath")

  if [[ -f "$filepath" ]]; then
    log "WARN" "$filename ya existe, no se sobrescribirá"
    return 1
  else
    echo "$content" >"$filepath"
    log "SUCCESS" "$filename creado"
    return 0
  fi
}

# ========================
# MIDDLEWARE CONTENT GENERATORS
# ========================

# Generar contenido del middleware de paginación
generate_pagination_middleware_content() {
  cat <<'EOF'
// src/interfaces/http/middlewares/pagination.middleware.js

export function paginationMiddleware(req, res, next) {
  const page = parseInt(req.query.page) || 1;
  const limit = Math.min(parseInt(req.query.limit) || 10, 100);
  const offset = (page - 1) * limit;

  req.pagination = { page, limit, offset };
  next();
}
EOF
}

# Generar contenido del middleware de filtros
generate_filters_middleware_content() {
  cat <<'EOF'
// src/interfaces/http/middlewares/filters.middleware.js

export function filtersMiddleware(filterableFields = []) {
  return (req, res, next) => {
    const filters = {};
    for (const field of filterableFields) {
      if (req.query[field] !== undefined) {
        filters[field] = req.query[field];
      }
    }
    req.filters = filters;
    next();
  };
}
EOF
}

# Generar contenido del middleware de búsqueda
generate_search_middleware_content() {
  cat <<'EOF'
// src/interfaces/http/middlewares/search.middleware.js

export function searchMiddleware(searchableFields = []) {
  return (req, res, next) => {
    const q = req.query.q;
    if (q && searchableFields.length > 0) {
      req.search = { query: q, fields: searchableFields };
    }
    next();
  };
}
EOF
}

# Generar contenido del middleware de ordenamiento
generate_sort_middleware_content() {
  cat <<'EOF'
// src/interfaces/http/middlewares/sort.middleware.js

export function sortMiddleware(sortableFields = []) {
  return (req, res, next) => {
    const { sortBy, order } = req.query;

    if (sortBy && sortableFields.includes(sortBy)) {
      req.sort = {
        sortBy,
        order: order?.toLowerCase() === 'asc' ? 'asc' : 'desc',
      };
    }

    next();
  };
}
EOF
}

# Generar contenido del archivo principal de middlewares
generate_main_middleware_content() {
  cat <<'EOF'
// src/interfaces/http/middlewares/query.middlewares.js
import { searchMiddleware } from './search.middleware.js';
import { filtersMiddleware } from './filters.middleware.js';
import { sortMiddleware } from './sort.middleware.js';
import { paginationMiddleware } from './pagination.middleware.js';

export function createQueryMiddlewares({
  searchableFields = [],
  filterableFields = [],
  sortableFields = []
}) {
  return [
    searchMiddleware(searchableFields),
    filtersMiddleware(filterableFields),
    sortMiddleware(sortableFields),
    paginationMiddleware,
  ];
}
EOF
}

# ========================
# MIDDLEWARE CREATION FUNCTIONS
# ========================

# Crear directorio de middlewares
create_middlewares_directory() {
  log "INFO" "Creando directorio de middlewares..."

  if mkdir -p "$QUERY_MIDDLEWARE_PATH"; then
    log "SUCCESS" "Directorio $QUERY_MIDDLEWARE_PATH creado/verificado"
  else
    log "ERROR" "Error creando directorio $QUERY_MIDDLEWARE_PATH"
    return 1
  fi
}

# Crear middleware de paginación
create_pagination_middleware() {
  log "INFO" "Creando middleware de paginación..."
  create_file_if_not_exists \
    "$QUERY_MIDDLEWARE_PATH/pagination.middleware.js" \
    "$(generate_pagination_middleware_content)"
}

# Crear middleware de filtros
create_filters_middleware() {
  log "INFO" "Creando middleware de filtros..."
  create_file_if_not_exists \
    "$QUERY_MIDDLEWARE_PATH/filters.middleware.js" \
    "$(generate_filters_middleware_content)"
}

# Crear middleware de búsqueda
create_search_middleware() {
  log "INFO" "Creando middleware de búsqueda..."
  create_file_if_not_exists \
    "$QUERY_MIDDLEWARE_PATH/search.middleware.js" \
    "$(generate_search_middleware_content)"
}

# Crear middleware de ordenamiento
create_sort_middleware() {
  log "INFO" "Creando middleware de ordenamiento..."
  create_file_if_not_exists \
    "$QUERY_MIDDLEWARE_PATH/sort.middleware.js" \
    "$(generate_sort_middleware_content)"
}

# Crear archivo principal de middlewares
create_main_middleware_file() {
  log "INFO" "Creando archivo principal de middlewares..."
  create_file_if_not_exists \
    "$QUERY_MIDDLEWARE_PATH/query.middlewares.js" \
    "$(generate_main_middleware_content)"
}

# ========================
# MAIN FUNCTION
# ========================
main() {
  log "INFO" "Iniciando generación de middlewares de consulta..."

  # Ejecutar funciones en orden
  create_middlewares_directory
  create_pagination_middleware
  create_filters_middleware
  create_search_middleware
  create_sort_middleware
  create_main_middleware_file

  log "SUCCESS" "Generación de middlewares de consulta completada"
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
