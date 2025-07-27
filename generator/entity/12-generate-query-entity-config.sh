#!/bin/bash
# shellcheck disable=SC2154
# Query Entity Config Generator
set -e

# Función principal
main() {
  # Validar variables requeridas
  validate_required_variables

  # Inicializar variables del proyecto
  init_project_variables

  # Generar configuración de query
  generate_query_config
}

# Función para validar variables requeridas
validate_required_variables() {
  if [[ -z "${SCHEMA_CONTENT:-}" ]]; then
    echo "❌ Error: La variable SCHEMA_CONTENT es requerida"
    return 1
  fi

  if [[ -z "${entity:-}" ]]; then
    echo "❌ Error: La variable entity es requerida"
    echo "Uso: $0 <entity>"
    echo "Ejemplo: $0 User"
    return 1
  fi
}

# Función para inicializar variables del proyecto
init_project_variables() {
  readonly SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
  # No redefinir PROJECT_ROOT si ya existe (puede venir de otros módulos)
  if [[ -z "${PROJECT_ROOT:-}" ]]; then
    PROJECT_ROOT="$(cd "$SCRIPT_DIR/../.." && pwd)"
  fi
  readonly entity_lc="${entity,,}"
  readonly output_dir="src/interfaces/http/$entity_lc"
  readonly output_file="$output_dir/query-${entity_lc}-config.js"
}

# Función para generar la configuración de query
generate_query_config() {
  # Crear directorio de salida
  mkdir -p "$output_dir"

  # Generar configuración JSON
  local query_config_json
  query_config_json=$(generate_query_config_json) || {
    echo "❌ Error al generar configuración de query"
    return 1
  }

  # Extraer arrays JavaScript
  local searchable_js sortable_js filterable_js
  searchable_js=$(extract_js_array "$query_config_json" "searchableFields")
  sortable_js=$(extract_js_array "$query_config_json" "sortableFields")
  filterable_js=$(extract_js_array "$query_config_json" "filterableFields")

  # Crear archivo de configuración
  create_query_config_file "$searchable_js" "$sortable_js" "$filterable_js"

  echo "✅ Query config generado: $output_file"
}

# Función para generar la configuración JSON desde el schema
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

        console.log(JSON.stringify({ 
            searchableFields, 
            sortableFields, 
            filterableFields 
        }));
    " "$SCHEMA_CONTENT"
}

# Función para extraer array JavaScript desde JSON
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

# Función para crear el archivo de configuración
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

# Manejo de argumentos si se ejecuta directamente
parse_arguments() {
  if [[ $# -ge 1 ]]; then
    entity="$1"
  fi
}

# Función de ayuda
show_help() {
  cat <<EOF
Uso: $0 <entity>

Genera configuración de query para una entidad basada en SCHEMA_CONTENT.

Argumentos:
  entity          Nombre de la entidad (ej: User, Product)

Variables de entorno requeridas:
  SCHEMA_CONTENT  JSON con la definición del schema de la entidad

Ejemplo:
  export SCHEMA_CONTENT='{"fields":[{"name":"id","type":"string"},{"name":"name","type":"string","searchable":true}]}'
  $0 User

EOF
}

# Ejecutar si se llama directamente
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
  # Mostrar ayuda si se solicita
  if [[ "${1:-}" == "-h" || "${1:-}" == "--help" ]]; then
    show_help
    exit 0
  fi

  parse_arguments "$@"
  main "$@"
fi

# Llamada implícita si fue sourced desde otro script
if [[ -n "${SCHEMA_CONTENT:-}" && -n "${entity:-}" ]]; then
  main "$@"
fi
