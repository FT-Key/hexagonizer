#!/bin/bash
# generator/entity/12-generate-query-entity-config.sh
# Query Entity Config Generator
# shellcheck disable=SC2154
set -e

source "$PROJECT_ROOT/generator/common/logging.sh"

# ===================================
# Main
# ===================================
main() {
  validate_required_variables || exit 1
  init_project_variables
  generate_query_config
}

validate_required_variables() {
  if [[ -z "${SCHEMA_CONTENT:-}" ]]; then
    log "ERROR" "SCHEMA_CONTENT variable is required"
    return 1
  fi

  if [[ -z "${entity:-}" ]]; then
    log "ERROR" "Entity variable is required"
    echo "Usage: $0 <entity>"
    echo "Example: $0 User"
    return 1
  fi
}

init_project_variables() {
  readonly SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
  if [[ -z "${PROJECT_ROOT:-}" ]]; then
    PROJECT_ROOT="$(cd "$SCRIPT_DIR/../.." && pwd)"
  fi
  readonly entity_lc="${entity,,}"
  readonly output_dir="src/interfaces/http/$entity_lc"
  readonly output_file="$output_dir/query-${entity_lc}-config.js"
}

generate_query_config() {
  mkdir -p "$output_dir"
  log "INFO" "📁 Directory created or ensured: $output_dir"

  local query_config_json
  if ! query_config_json=$(generate_query_config_json); then
    log "ERROR" "Error generating query config from schema"
    return 1
  fi

  local searchable_js sortable_js filterable_js
  searchable_js=$(extract_js_array "$query_config_json" "searchableFields")
  sortable_js=$(extract_js_array "$query_config_json" "sortableFields")
  filterable_js=$(extract_js_array "$query_config_json" "filterableFields")

  create_query_config_file "$searchable_js" "$sortable_js" "$filterable_js"
  log "SUCCESS" "Query config generated successfully: $output_file"
}

generate_query_config_json() {
  node -e "
    const input = JSON.parse(process.argv[1]);
    const fields = input.fields || [];

    const searchableFields = fields
      .filter(f => !f.sensitive && (f.searchable !== false))
      .map(f => f.name);

    const sortableFields = fields
      .filter(f => !f.sensitive && (f.sortable !== false))
      .map(f => f.name);

    const filterableFields = fields
      .filter(f => !f.sensitive && (f.filterable !== false))
      .map(f => f.name);

    console.log(JSON.stringify({ searchableFields, sortableFields, filterableFields }));
  " "$SCHEMA_CONTENT"
}

extract_js_array() {
  local json="$1"
  local field="$2"

  node -e "
    const input = JSON.parse(process.argv[1]);
    const fieldName = process.argv[2];
    const array = input[fieldName] || [];
    console.log(array.map(f => '\"' + f + '\"').join(', '));
  " "$json" "$field"
}

create_query_config_file() {
  local searchable_js="$1"
  local sortable_js="$2"
  local filterable_js="$3"

  cat >"$output_file" <<EOF
// Configuración de query para la entidad $entity

export const ${entity_lc}QueryConfig = {
  searchableFields: [${searchable_js}],  // campos para búsqueda por texto (q)
  sortableFields: [${sortable_js}],      // campos permitidos para ordenar
  filterableFields: [${filterable_js}],  // campos permitidos para filtro exacto
};
EOF
}

parse_arguments() {
  if [[ $# -ge 1 ]]; then
    entity="$1"
  fi
}

show_help() {
  cat <<EOF
Usage: $0 <entity>

Generates query configuration for an entity based on SCHEMA_CONTENT.

Arguments:
  entity          Entity name (e.g. User, Product)

Required environment variables:
  SCHEMA_CONTENT  JSON with the entity schema definition

Example:
  export SCHEMA_CONTENT='{"fields":[{"name":"id","type":"string"},{"name":"name","type":"string","searchable":true}]}'
  $0 User

EOF
}

# ===================================
# Ejecución
# ===================================
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
  if [[ "${1:-}" == "-h" || "${1:-}" == "--help" ]]; then
    show_help
    exit 0
  fi

  parse_arguments "$@"
  main "$@"
fi

if [[ -n "${SCHEMA_CONTENT:-}" && -n "${entity:-}" ]]; then
  main "$@"
fi
