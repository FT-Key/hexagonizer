#!/bin/bash
# hexagon/common/generate-query-middlewares.sh

query_middleware_path="src/interfaces/http/middlewares"

mkdir -p "$query_middleware_path"

create_file_if_not_exists() {
  local filepath=$1
  local content=$2

  if [ -f "$filepath" ]; then
    echo "⚠️  $filepath ya existe, no se sobrescribirá."
  else
    echo "$content" >"$filepath"
    echo "✅ $filepath creado."
  fi
}

# === Query Middlewares ===

create_file_if_not_exists "$query_middleware_path/pagination.middleware.js" "$(
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
)"

create_file_if_not_exists "$query_middleware_path/filters.middleware.js" "$(
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
)"

create_file_if_not_exists "$query_middleware_path/search.middleware.js" "$(
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
)"

create_file_if_not_exists "$query_middleware_path/sort.middleware.js" "$(
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
)"

create_file_if_not_exists "$query_middleware_path/query.middlewares.js" "$(
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
)"
