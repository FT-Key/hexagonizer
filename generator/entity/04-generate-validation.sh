#!/bin/bash
# generator/entity/04-generate-validate.sh
# 1.5 VALIDATE
# shellcheck disable=SC2154
set -e

validate_file="src/domain/$entity/validate-$entity.js"

if [[ -f "$validate_file" && "$AUTO_CONFIRM" != true ]]; then
  read -r -p "⚠️  El archivo $validate_file ya existe. ¿Desea sobrescribirlo? [y/n]: " confirm
  if [[ ! "$confirm" =~ ^[Yy]$ ]]; then
    echo "⏭️  Se omitió la generación de $validate_file"
    exit 0
  fi
fi

PROJECT_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"

if [[ -n "$SCHEMA_FILE" ]]; then
  parsed_json=$(node "$PROJECT_ROOT/generator/utils/parse-schema-fields.js" "$SCHEMA_FILE")
elif [[ -n "$SCHEMA_CONTENT" ]]; then
  parsed_json=$(echo "$SCHEMA_CONTENT" | node "$PROJECT_ROOT/generator/utils/parse-schema-fields.js")
else
  echo "❌ No hay esquema definido para parsear en generate-validation"
  exit 1
fi

# Leer campos del JSON
while IFS='=' read -r key value; do
  eval "$key=$value"
done < <(
  echo "$parsed_json" | node -e "
    const input = JSON.parse(require('fs').readFileSync(0, 'utf8'));
    const fields = input.fields || [];
    const escape = str => (str || '').replace(/'/g, \"'\\\\''\");

    fields.forEach((f, i) => {
      const name = escape(f.name);
      const required = f.required ? 'true' : 'false';
      const type = escape(f.type || '');
      const enums = (f.enum || []).map(e => escape(e)).join(',');
      const enumDisplay = (f.enum || []).map(e => escape(e)).join(', ');
      const format = escape(f.format || '');
      const minLength = f.minLength ?? '';
      const maxLength = f.maxLength ?? '';
      const min = f.min ?? '';
      const max = f.max ?? '';
      const nullable = f.nullable ? 'true' : 'false';

      console.log(\`v_names[\${i}]='\${name}'\`);
      console.log(\`v_requireds[\${i}]='\${required}'\`);
      console.log(\`v_types[\${i}]='\${type}'\`);
      console.log(\`v_enums[\${i}]='\${enums}'\`);
      console.log(\`v_enum_display[\${i}]='\${enumDisplay}'\`);
      console.log(\`v_formats[\${i}]='\${format}'\`);
      console.log(\`v_minLengths[\${i}]='\${minLength}'\`);
      console.log(\`v_maxLengths[\${i}]='\${maxLength}'\`);
      console.log(\`v_mins[\${i}]='\${min}'\`);
      console.log(\`v_maxs[\${i}]='\${max}'\`);
      console.log(\`v_nullables[\${i}]='\${nullable}'\`);
    });
  "
)

validation_lines=""

for i in "${!v_names[@]}"; do
  name="${v_names[$i]}"
  required="${v_requireds[$i]}"
  type="${v_types[$i]}"
  enum="${v_enums[$i]}"
  enum_display="${v_enum_display[$i]}"
  format="${v_formats[$i]}"
  minLength="${v_minLengths[$i]}"
  maxLength="${v_maxLengths[$i]}"
  min="${v_mins[$i]}"
  max="${v_maxs[$i]}"
  nullable="${v_nullables[$i]}"

  [[ -z "$name" || "$name" == "null" ]] && continue

  field_lines=""

  if [[ "$required" == "true" && "$nullable" != "true" ]]; then
    field_lines+="  if (data.$name === undefined || data.$name === null) throw new Error('$name is required');"$'\n'
  fi

  if [[ -n "$type" ]]; then
    case "$type" in
    string | number | boolean | object)
      field_lines+="  if (data.$name != null && typeof data.$name !== '$type') throw new Error('$name must be a $type');"$'\n'
      ;;
    esac
  fi

  if [[ -n "$minLength" ]]; then
    field_lines+="  if (data.$name && data.$name.length < $minLength) throw new Error('$name must have at least $minLength characters');"$'\n'
  fi

  if [[ -n "$maxLength" ]]; then
    field_lines+="  if (data.$name && data.$name.length > $maxLength) throw new Error('$name must have at most $maxLength characters');"$'\n'
  fi

  if [[ -n "$min" ]]; then
    field_lines+="  if (data.$name < $min) throw new Error('$name must be >= $min');"$'\n'
  fi

  if [[ -n "$max" ]]; then
    field_lines+="  if (data.$name > $max) throw new Error('$name must be <= $max');"$'\n'
  fi

  if [[ "$format" == "email" ]]; then
    field_lines+="  if (data.$name && !/^\\S+@\\S+\\.\\S+$/.test(data.$name)) throw new Error('$name must be a valid email');"$'\n'
  fi

  if [[ "$format" == "time" ]]; then
    field_lines+="  if (data.$name && !/^\\d{2}:\\d{2}$/.test(data.$name)) throw new Error('$name must be in HH:MM format');"$'\n'
  fi

  if [[ -n "$enum" ]]; then
    IFS=',' read -r -a enum_array <<<"$enum"
    enum_js="["
    for val in "${enum_array[@]}"; do enum_js+="'$val',"; done
    enum_js="${enum_js%,}]"
    field_lines+="  if (data.$name && !$enum_js.includes(data.$name)) throw new Error('$name must be one of: $enum_display');"$'\n'
  fi

  # Agregar bloque con salto de línea solo si field_lines no está vacío
  if [[ -n "$field_lines" ]]; then
    [[ -n "$validation_lines" ]] && validation_lines+=$'\n'
    validation_lines+="$field_lines"
  fi
done

# Escribir archivo final
cat <<EOF >"$validate_file"
export function validate${EntityPascal}(data) {
$validation_lines
  return true;
}
EOF

echo "✅ Validación generada: $validate_file"
