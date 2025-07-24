#!/bin/bash
# shellcheck disable=SC2034,SC2154

SCHEMA_DIR="./hexagon/entity/entity-schemas"

if [[ "$USE_JSON" == true ]]; then
  command -v jq >/dev/null 2>&1 || {
    echo >&2 "❌ Error: jq no está instalado."
    exit 1
  }

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

    SCHEMA_JSON="${json_files[selected_num - 1]}"
  else
    if [[ ! -f "$input_path" ]]; then
      echo "❌ No se encontró el archivo JSON: $input_path"
      exit 1
    fi
    SCHEMA_JSON="$input_path"
  fi

  entity=$(jq -r '.name' "$SCHEMA_JSON")
  if [[ "$entity" == "null" ]] || [[ -z "$entity" ]]; then
    echo "❌ No se pudo leer el nombre de la entidad del JSON."
    exit 1
  fi

  # ✅ Extraer campos personalizados del JSON
  custom_fields=$(jq '.fields // []' "$SCHEMA_JSON")

  # ✅ Extraer métodos personalizados (opcional)
  custom_methods=$(jq '.methods // []' "$SCHEMA_JSON")

else
  read -r -p "📝 Nombre de la entidad (ej. user, product): " entity
  custom_fields='[]'
  custom_methods='[]'
fi

# ---------------------
# ✅ VALIDACIÓN DEL NOMBRE
# ---------------------

entity=$(echo "$entity" | sed 's/^[[:space:]]*//;s/[[:space:]]*$//')
entity=$(echo "$entity" | tr -d '[:space:]')
entity=$(echo "$entity" | tr -cd '[:alnum:]')
entity="${entity,,}"

if [[ -z "$entity" ]]; then
  echo "❌ Error: El nombre de la entidad no puede estar vacío o inválido."
  exit 1
fi

EntityPascal="$(tr '[:lower:]' '[:upper:]' <<<"${entity:0:1}")${entity:1}"
