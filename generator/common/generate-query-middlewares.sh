#!/bin/bash
# generator/common/generate-query-middlewares.sh

set -e

source "$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)/logging.sh"

readonly QUERY_MIDDLEWARE_PATH="src/interfaces/http/middlewares"

create_files() {
  mkdir -p "$QUERY_MIDDLEWARE_PATH"

  cat > "$QUERY_MIDDLEWARE_PATH/pagination.middleware.js" <<'PAGINATION'
export function paginationMiddleware(req, res, next) {
  const page = parseInt(req.query.page) || 1;
  const limit = Math.min(parseInt(req.query.limit) || 10, 100);
  const offset = (page - 1) * limit;
  req.pagination = { page, limit, offset };
  next();
}
PAGINATION

  cat > "$QUERY_MIDDLEWARE_PATH/filters.middleware.js" <<'FILTERS'
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
FILTERS

  cat > "$QUERY_MIDDLEWARE_PATH/search.middleware.js" <<'SEARCH'
export function searchMiddleware(searchableFields = []) {
  return (req, res, next) => {
    const q = req.query.q;
    if (q && searchableFields.length > 0) {
      req.search = { query: q, fields: searchableFields };
    }
    next();
  };
}
SEARCH

  cat > "$QUERY_MIDDLEWARE_PATH/sort.middleware.js" <<'SORT'
export function sortMiddleware(sortableFields = []) {
  return (req, res, next) => {
    const { sortBy, order } = req.query;
    if (sortBy && sortableFields.includes(sortBy)) {
      req.sort = { sortBy, order: order?.toLowerCase() === 'asc' ? 'asc' : 'desc' };
    }
    next();
  };
}
SORT

  cat > "$QUERY_MIDDLEWARE_PATH/query.middlewares.js" <<'QUERY'
import { searchMiddleware } from './search.middleware.js';
import { filtersMiddleware } from './filters.middleware.js';
import { sortMiddleware } from './sort.middleware.js';
import { paginationMiddleware } from './pagination.middleware.js';

export function createQueryMiddlewares({ searchableFields = [], filterableFields = [], sortableFields = [] }) {
  return [
    searchMiddleware(searchableFields),
    filtersMiddleware(filterableFields),
    sortMiddleware(sortableFields),
    paginationMiddleware,
  ];
}
QUERY

  log "SUCCESS" "Middlewares de consulta creados"
}

if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
  create_files
fi
