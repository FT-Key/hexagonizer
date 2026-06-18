#!/bin/bash
# generator/common/generate-query-utils.sh

set -e

source "$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)/logging.sh"

main() {
  mkdir -p "src/utils"

  cat > "src/utils/query-utils.js" <<'EOF'
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

export function applyPagination(items, pagination = null) {
  if (!pagination) return items;
  const offset = pagination.offset ?? 0;
  const limit = pagination.limit ?? items.length;
  return items.slice(offset, offset + limit);
}
EOF

  log "SUCCESS" "Utilidades de consulta generadas"
}

if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
  main "$@"
fi
