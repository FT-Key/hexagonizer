#!/bin/bash
# hexagon/common/generate-query-utils.sh

UTILS_PATH="src/utils"
QUERY_UTILS_FILE="$UTILS_PATH/query-utils.js"

mkdir -p "$UTILS_PATH"

AUTO_CONFIRM=false
if [[ "$1" == "-y" ]]; then
  AUTO_CONFIRM=true
fi

confirm_action() {
  local prompt=$1
  if [ "$AUTO_CONFIRM" = true ]; then
    return 0
  fi

  read -rp "$prompt [y/n]: " response
  case "$response" in
  [yY][eE][sS] | [yY]) return 0 ;;
  *) return 1 ;;
  esac
}

create_query_utils() {
  cat <<'EOF' >"$QUERY_UTILS_FILE"
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

# Crear o preguntar si sobrescribir
if [ -f "$QUERY_UTILS_FILE" ]; then
  echo "⚠️  $QUERY_UTILS_FILE ya existe."
  if confirm_action "¿Deseás sobrescribirlo?"; then
    create_query_utils
    echo "✅ $QUERY_UTILS_FILE sobrescrito."
  else
    echo "❌ No se sobrescribió $QUERY_UTILS_FILE."
  fi
else
  create_query_utils
  echo "✅ $QUERY_UTILS_FILE creado."
fi
