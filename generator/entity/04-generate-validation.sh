#!/bin/bash
# generator/entity/04-generate-validation.sh
# shellcheck disable=SC2154
set -e

validate_file="src/domain/$entity/validate-$entity.js"

extract_validation_data() {
  while IFS='=' read -r key value; do
    eval "$key=$value"
  done < <(
    echo "$PARSED_FIELDS" | node -e "
      const input = JSON.parse(require('fs').readFileSync(0, 'utf8'));
      const fields = input.fields || [];
      const escape = str => (str || '').replace(/'/g, \"'\\\\''\");

      fields.forEach((f, i) => {
        const props = {
          name: escape(f.name),
          required: f.required ? 'true' : 'false',
          type: escape(f.type || ''),
          enums: (f.enum || []).map(escape).join(','),
          enumDisplay: (f.enum || []).map(escape).join(', '),
          format: escape(f.format || ''),
          minLength: f.minLength ?? '',
          maxLength: f.maxLength ?? '',
          min: f.min ?? '',
          max: f.max ?? '',
          nullable: f.nullable ? 'true' : 'false'
        };

        Object.entries(props).forEach(([key, val]) => {
          console.log(\`v_\${key}s[\${i}]='\${val}'\`);
        });
      });
    "
  )
}

build_field_validation() {
  local name="$1" required="$2" type="$3" enum="$4" enum_display="$5"
  local format="$6" minLength="$7" maxLength="$8" min="$9" max="${10}" nullable="${11}"
  local field_lines=""

  [[ -z "$name" || "$name" == "null" ]] && return

  # Required validation
  if [[ "$required" == "true" && "$nullable" != "true" ]]; then
    field_lines+="  if (data.$name === undefined || data.$name === null) throw new Error('$name is required');"$'\n'
  fi

  # Type validation
  case "$type" in
  string | number | boolean | object)
    field_lines+="  if (data.$name != null && typeof data.$name !== '$type') throw new Error('$name must be a $type');"$'\n'
    ;;
  esac

  # Length validations
  [[ -n "$minLength" ]] && field_lines+="  if (data.$name && data.$name.length < $minLength) throw new Error('$name must have at least $minLength characters');"$'\n'
  [[ -n "$maxLength" ]] && field_lines+="  if (data.$name && data.$name.length > $maxLength) throw new Error('$name must have at most $maxLength characters');"$'\n'

  # Numeric range validations
  [[ -n "$min" ]] && field_lines+="  if (data.$name < $min) throw new Error('$name must be >= $min');"$'\n'
  [[ -n "$max" ]] && field_lines+="  if (data.$name > $max) throw new Error('$name must be <= $max');"$'\n'

  # Format validations
  case "$format" in
  email) field_lines+="  if (data.$name && !/^\\S+@\\S+\\.\\S+$/.test(data.$name)) throw new Error('$name must be a valid email');"$'\n' ;;
  time) field_lines+="  if (data.$name && !/^\\d{2}:\\d{2}$/.test(data.$name)) throw new Error('$name must be in HH:MM format');"$'\n' ;;
  esac

  # Enum validation
  if [[ -n "$enum" ]]; then
    IFS=',' read -r -a enum_array <<<"$enum"
    local enum_js="["
    for val in "${enum_array[@]}"; do enum_js+="'$val',"; done
    enum_js="${enum_js%,}]"
    field_lines+="  if (data.$name && !$enum_js.includes(data.$name)) throw new Error('$name must be one of: $enum_display');"$'\n'
  fi

  # Add to global validation if not empty
  if [[ -n "$field_lines" ]]; then
    [[ -n "$validation_lines" ]] && validation_lines+=$'\n'
    validation_lines+="$field_lines"
  fi
}

build_validations() {
  validation_lines=""

  for i in "${!v_names[@]}"; do
    build_field_validation \
      "${v_names[$i]}" "${v_requireds[$i]}" "${v_types[$i]}" "${v_enums[$i]}" \
      "${v_enumDisplays[$i]}" "${v_formats[$i]}" "${v_minLengths[$i]}" \
      "${v_maxLengths[$i]}" "${v_mins[$i]}" "${v_maxs[$i]}" "${v_nullables[$i]}"
  done
}

confirm_file_overwrite() {
  if [[ -f "$validate_file" && "$AUTO_CONFIRM" != true ]]; then
    read -r -p "⚠️  El archivo $validate_file ya existe. ¿Desea sobrescribirlo? [y/n]: " confirm
    [[ ! "$confirm" =~ ^[Yy]$ ]] && {
      echo "⏭️  Se omitió la generación de $validate_file"
      exit 0
    }
  fi
}

write_validation_file() {
  cat >"$validate_file" <<EOF
export function validate${EntityPascal}(data) {
$validation_lines
  return true;
}
EOF
}

# Main execution
extract_validation_data
build_validations
confirm_file_overwrite
write_validation_file

echo "✅ Validación generada: $validate_file"
