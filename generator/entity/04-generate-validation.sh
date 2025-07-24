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
  # Usar archivo físico
  parsed_json=$(node "$PROJECT_ROOT/generator/utils/parse-schema-fields.js" "$SCHEMA_FILE")
elif [[ -n "$SCHEMA_CONTENT" ]]; then
  # Usar JSON en memoria
  parsed_json=$(echo "$SCHEMA_CONTENT" | node "$PROJECT_ROOT/generator/utils/parse-schema-fields.js")
else
  echo "❌ No hay esquema definido para parsear en generate-validation"
  exit 1
fi

# Exportar arrays legibles por Bash, con valores reales (no literales)
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

  if [[ "$required" == "true" && "$nullable" != "true" ]]; then
    validation_lines+=$(printf "  if (data.%s === undefined || data.%s === null) throw new Error('%s is required');\n" "$name" "$name" "$name")
  fi

  if [[ -n "$type" ]]; then
    case "$type" in
    string | number | boolean | object)
      validation_lines+=$(printf "  if (data.%s != null && typeof data.%s !== '%s') throw new Error('%s must be a %s');\n" "$name" "$name" "$type" "$name" "$type")
      ;;
    esac
  fi

  if [[ -n "$minLength" ]]; then
    validation_lines+=$(printf "  if (data.%s && data.%s.length < %s) throw new Error('%s must have at least %s characters');\n" "$name" "$name" "$minLength" "$name" "$minLength")
  fi

  if [[ -n "$maxLength" ]]; then
    validation_lines+=$(printf "  if (data.%s && data.%s.length > %s) throw new Error('%s must have at most %s characters');\n" "$name" "$name" "$maxLength" "$name" "$maxLength")
  fi

  if [[ -n "$min" ]]; then
    validation_lines+=$(printf "  if (data.%s < %s) throw new Error('%s must be >= %s');\n" "$name" "$min" "$name" "$min")
  fi

  if [[ -n "$max" ]]; then
    validation_lines+=$(printf "  if (data.%s > %s) throw new Error('%s must be <= %s');\n" "$name" "$max" "$name" "$max")
  fi

  if [[ "$format" == "email" ]]; then
    validation_lines+=$(printf "  if (data.%s && !/^\\S+@\\S+\\.\\S+$/.test(data.%s)) throw new Error('%s must be a valid email');\n" "$name" "$name" "$name")
  fi

  if [[ "$format" == "time" ]]; then
    validation_lines+=$(printf "  if (data.%s && !/^\\d{2}:\\d{2}$/.test(data.%s)) throw new Error('%s must be in HH:MM format');\n" "$name" "$name" "$name")
  fi

  if [[ -n "$enum" ]]; then
    # Convertir enums separados por comas en array JS: ['val1','val2']
    IFS=',' read -r -a enum_array <<<"$enum"
    enum_js="["
    for val in "${enum_array[@]}"; do
      enum_js+="'$val',"
    done
    enum_js="${enum_js%,}]" # quita la última coma y cierra array

    validation_lines+=$(printf "  if (data.%s && !%s.includes(data.%s)) throw new Error('%s must be one of: %s');\n" "$name" "$enum_js" "$name" "$name" "$enum_display")
  fi
done

cat <<EOF >"$validate_file"
export function validate${EntityPascal}(data) {
$validation_lines  return true;
}
EOF

echo "✅ Validación generada: $validate_file"
