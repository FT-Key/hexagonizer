#!/bin/bash
# 13-generate-query-entity-config.sh

if [ -z "$fields" ] || [ -z "$entity" ]; then
  echo "❌ Error: faltan campos o nombre de entidad."
  exit 1
fi

entity_lc="${entity,,}"

# Campos que deben ser excluidos explícitamente por nombre (aunque no sean sensibles)
excluded_fields=("deletedAt" "ownedBy")

# Filtrar campos: NO sensibles y que NO estén en la lista de excluidos
valid_fields=$(echo "$fields" | jq -r --argjson excluded "$(printf '%s\n' "${excluded_fields[@]}" | jq -R . | jq -s .)" '
  map(select(
    ((.sensitive | not) or (.sensitive == false)) and
    (.name as $n | $excluded | index($n) | not)
  )) | map(.name) | .[]')

# Eliminar duplicados y ordenar
mapfile -t sorted_fields < <(echo "$valid_fields" | sort -u)

# Convertir a listas JS
array_to_js_list() {
  local arr=("$@")
  local res=""
  for e in "${arr[@]}"; do
    res+="\"$e\", "
  done
  echo "${res%, }"
}

searchable_js=$(array_to_js_list "${sorted_fields[@]}")
sortable_js=$(array_to_js_list "${sorted_fields[@]}")
filterable_js=$(array_to_js_list "${sorted_fields[@]}")

# Generar archivo de salida
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
