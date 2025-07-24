#!/bin/bash
# shellcheck disable=SC2034,SC2154

SCHEMA_DIR="./hexagonizer/entity/entity-schemas"
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "$SCRIPT_DIR/../.." && pwd)"

if [[ "$USE_JSON" == true ]]; then
  echo "📁 Ingrese ruta al archivo JSON de esquema de entidad"
  echo "   (o presione Enter para listar archivos disponibles en $SCHEMA_DIR):"
  read -r input_path

  if [[ -z "$input_path" ]]; then
    if [[ ! -d "$SCHEMA_DIR" ]]; then
      echo "❌ Directorio no existe: $SCHEMA_DIR"
      exit 1
    fi

    mapfile -t json_files < <(find "$SCHEMA_DIR" -maxdepth 1 -type f -name '*.json' | sort)
    if [[ ${#json_files[@]} -eq 0 ]]; then
      echo "❌ No se encontraron archivos JSON en $SCHEMA_DIR"
      exit 1
    fi

    echo "Seleccione el archivo JSON para usar:"
    for i in "${!json_files[@]}"; do
      fname=$(basename "${json_files[i]}")
      echo "  $((i + 1))) $fname"
    done

    read -r -p "Ingrese número (1-${#json_files[@]}): " selected_num

    if ! [[ "$selected_num" =~ ^[0-9]+$ ]] || ((selected_num < 1 || selected_num > ${#json_files[@]})); then
      echo "❌ Selección inválida"
      exit 1
    fi

    SCHEMA_FILE="${json_files[selected_num - 1]}"
  else
    if [[ ! -f "$input_path" ]]; then
      echo "❌ No se encontró el archivo JSON: $input_path"
      exit 1
    fi
    SCHEMA_FILE="$input_path"
  fi

  # Leer contenido para parsear en memoria
  schema_content=$(cat "$SCHEMA_FILE")
  ENTITY_NAME=$(basename "$SCHEMA_FILE" .json | tr '[:upper:]' '[:lower:]')

  # SCHEMA_CONTENT queda vacío porque usamos archivo
  SCHEMA_CONTENT=""

else
  read -r -p "📝 Nombre de la entidad (ej. user, product): " entity
  ENTITY_NAME="${entity,,}"

  schema_content=$(
    cat <<EOF
{
  "name": "$ENTITY_NAME",
  "fields": [
    { "name": "id", "required": true },
    { "name": "active", "default": true },
    { "name": "createdAt", "default": "new Date()" },
    { "name": "updatedAt", "default": "new Date()" },
    { "name": "deletedAt", "default": null },
    { "name": "ownedBy", "default": null }
  ],
  "methods": []
}
EOF
  )

  SCHEMA_FILE=""
  SCHEMA_CONTENT="$schema_content"
fi

# Exportar variables para otros scripts
export entity="$ENTITY_NAME"
export SCHEMA_FILE
export SCHEMA_CONTENT
export schema_content

# Validar nombre entidad
entity_clean=$(echo "$ENTITY_NAME" | sed 's/^[[:space:]]*//;s/[[:space:]]*$//' | tr -cd '[:alnum:]')
EntityPascal="$(tr '[:lower:]' '[:upper:]' <<<"${entity_clean:0:1}")${entity_clean:1}"

if [[ -z "$entity_clean" ]]; then
  echo "❌ Error: El nombre de la entidad no puede estar vacío o inválido."
  exit 1
fi

export entity="$entity_clean"
export EntityPascal

if [[ -n "$SCHEMA_FILE" ]]; then
  FIELDS=$(node "$PROJECT_ROOT/generator/utils/parse-schema-fields.js" "$SCHEMA_FILE")
elif [[ -n "$SCHEMA_CONTENT" ]]; then
  FIELDS=$(echo "$SCHEMA_CONTENT" | node "$PROJECT_ROOT/generator/utils/parse-schema-fields.js")
else
  echo "❌ No se puede generar campos: sin esquema"
  exit 1
fi

export FIELDS

echo "✅ LoadSchema"
