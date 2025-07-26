#!/bin/bash
# generator/entity/02-load-schema.sh
# shellcheck disable=SC2034,SC2154
set -e

SCHEMA_DIR="./entity-schemas"

load_schema_from_json() {
  echo "📁 Ingrese ruta al archivo JSON de esquema de entidad"
  echo "   (o presione Enter para listar archivos disponibles en $SCHEMA_DIR):"
  read -r input_path

  if [[ -z "$input_path" ]]; then
    [[ ! -d "$SCHEMA_DIR" ]] && mkdir -p "$SCHEMA_DIR"

    mapfile -t json_files < <(find "$SCHEMA_DIR" -maxdepth 1 -type f -name '*.json' | sort)
    [[ ${#json_files[@]} -eq 0 ]] && {
      echo "❌ No se encontraron archivos JSON en $SCHEMA_DIR"
      exit 1
    }

    echo "Seleccione el archivo JSON para usar:"
    for i in "${!json_files[@]}"; do
      echo "  $((i + 1))) $(basename "${json_files[i]}")"
    done

    read -r -p "Ingrese número (1-${#json_files[@]}): " selected_num

    if ! [[ "$selected_num" =~ ^[0-9]+$ ]] || ((selected_num < 1 || selected_num > ${#json_files[@]})); then
      echo "❌ Selección inválida"
      exit 1
    fi

    SCHEMA_FILE="${json_files[selected_num - 1]}"
  else
    [[ ! -f "$input_path" ]] && {
      echo "❌ No se encontró el archivo JSON: $input_path"
      exit 1
    }
    SCHEMA_FILE="$input_path"
  fi

  SCHEMA_CONTENT=$(cat "$SCHEMA_FILE")
  ENTITY_NAME=$(basename "$SCHEMA_FILE" .json | tr '[:upper:]' '[:lower:]')
}

create_default_schema() {
  read -r -p "📝 Nombre de la entidad (ej. user, product): " entity
  ENTITY_NAME="${entity,,}"

  SCHEMA_CONTENT=$(
    cat <<EOF
{
  "name": "$ENTITY_NAME",
  "fields": [
    { "name": "id", "required": true },
    { "name": "active", "default": true },
    { "name": "createdAt", "default": "new Date()" },
    { "name": "updatedAt", "default": "new Date()" },
    { "name": "deletedAt", "default": null, "sensitive": true },
    { "name": "ownedBy", "default": null, "sensitive": true }
  ],
  "methods": []
}
EOF
  )
  SCHEMA_FILE=""
}

validate_entity_name() {
  local clean_name=$(echo "$ENTITY_NAME" | sed 's/^[[:space:]]*//;s/[[:space:]]*$//' | tr -cd '[:alnum:]')
  [[ -z "$clean_name" ]] && {
    echo "❌ Error: El nombre de la entidad no puede estar vacío o inválido."
    exit 1
  }

  entity="$clean_name"
  EntityPascal="$(tr '[:lower:]' '[:upper:]' <<<"${clean_name:0:1}")${clean_name:1}"
}

parse_schema_fields() {
  if [[ -n "$SCHEMA_FILE" ]]; then
    PARSED_FIELDS=$(node "$PROJECT_ROOT/generator/utils/parse-schema-fields.js" "$SCHEMA_FILE")
  elif [[ -n "$SCHEMA_CONTENT" ]]; then
    PARSED_FIELDS=$(echo "$SCHEMA_CONTENT" | node "$PROJECT_ROOT/generator/utils/parse-schema-fields.js")
  else
    echo "❌ No se puede generar campos: sin esquema"
    exit 1
  fi
}

# Main execution
if [[ "$USE_JSON" == true ]]; then
  load_schema_from_json
else
  create_default_schema
fi

validate_entity_name
parse_schema_fields

# Export variables for other scripts
export entity EntityPascal SCHEMA_FILE SCHEMA_CONTENT PARSED_FIELDS

echo "✅ LoadSchema: $entity ($EntityPascal)"
