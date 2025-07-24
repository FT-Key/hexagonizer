#!/bin/bash
# 12-generate-query-entity-config.sh
set -e

if [[ -z "$SCHEMA_CONTENT" || -z "$entity" ]]; then
  echo "❌ Error: faltan SCHEMA_CONTENT o nombre de entidad."
  exit 1
fi

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "$SCRIPT_DIR/../.." && pwd)"

query_config_json=$(echo "$SCHEMA_CONTENT" | node -e "
  const input = JSON.parse(require('fs').readFileSync(0, 'utf8'));
  const fields = input.fields || [];

  // Filtrar campos que NO sean sensibles y que tengan atributo true para cada tipo, por defecto true
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
") || {
  echo "❌ Error al generar configuración de query"
  exit 1
}

searchable_js=$(echo "$query_config_json" | node -e "
  const input = JSON.parse(require('fs').readFileSync(0, 'utf8'));
  console.log(input.searchableFields.map(f => '\"' + f + '\"').join(', '));
")

sortable_js=$(echo "$query_config_json" | node -e "
  const input = JSON.parse(require('fs').readFileSync(0, 'utf8'));
  console.log(input.sortableFields.map(f => '\"' + f + '\"').join(', '));
")

filterable_js=$(echo "$query_config_json" | node -e "
  const input = JSON.parse(require('fs').readFileSync(0, 'utf8'));
  console.log(input.filterableFields.map(f => '\"' + f + '\"').join(', '));
")

entity_lc="${entity,,}"
mkdir -p "src/interfaces/http/$entity_lc"
output_file="src/interfaces/http/${entity_lc}/query-${entity_lc}-config.js"

cat >"$output_file" <<EOF
// Configuración de query para la entidad $entity

export const ${entity_lc}QueryConfig = {
  searchableFields: [${searchable_js}],  // campos para búsqueda por texto (q)
  sortableFields: [${sortable_js}],      // campos permitidos para ordenar
  filterableFields: [${filterable_js}],  // campos permitidos para filtro exacto
};
EOF

echo "✅ Query config generado: $output_file"
