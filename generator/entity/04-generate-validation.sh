#!/bin/bash
# shellcheck disable=SC2154
# 1.5 VALIDATE
validate_file="src/domain/$entity/validate-$entity.js"

if [[ -f "$validate_file" && "$AUTO_CONFIRM" != true ]]; then
  read -r -p "⚠️  El archivo $validate_file ya existe. ¿Desea sobrescribirlo? [y/n]: " confirm
  if [[ ! "$confirm" =~ ^[Yy]$ ]]; then
    echo "⏭️  Se omitió la generación de $validate_file"
    exit 0
  fi
fi

field_count=$(echo "$fields" | jq '. | length')
validation_lines=""

for ((i = 0; i < field_count; i++)); do
  field=$(echo "$fields" | jq ".[$i]")
  name=$(echo "$field" | jq -r ".name")
  required=$(echo "$field" | jq -r ".required // false")
  type=$(echo "$field" | jq -r ".type // empty")
  enum=$(echo "$field" | jq -c ".enum // empty")
  format=$(echo "$field" | jq -r ".format // empty")
  minLength=$(echo "$field" | jq -r ".minLength // empty")
  maxLength=$(echo "$field" | jq -r ".maxLength // empty")
  min=$(echo "$field" | jq -r ".min // empty")
  max=$(echo "$field" | jq -r ".max // empty")
  nullable=$(echo "$field" | jq -r ".nullable // false")

  [[ -z "$name" || "$name" == "null" ]] && continue

  if [[ "$required" == "true" && "$nullable" != "true" ]]; then
    validation_lines+="  if (data.$name === undefined || data.$name === null) throw new Error('$name is required');"$'\n'
  fi

  if [[ -n "$type" ]]; then
    case "$type" in
    string | number | boolean | object)
      validation_lines+="  if (data.$name != null && typeof data.$name !== '$type') throw new Error('$name must be a $type');"$'\n'
      ;;
    esac
  fi

  if [[ -n "$minLength" ]]; then
    validation_lines+="  if (data.$name && data.$name.length < $minLength) throw new Error('$name must have at least $minLength characters');"$'\n'
  fi

  if [[ -n "$maxLength" ]]; then
    validation_lines+="  if (data.$name && data.$name.length > $maxLength) throw new Error('$name must have at most $maxLength characters');"$'\n'
  fi

  if [[ -n "$min" ]]; then
    validation_lines+="  if (data.$name < $min) throw new Error('$name must be >= $min');"$'\n'
  fi

  if [[ -n "$max" ]]; then
    validation_lines+="  if (data.$name > $max) throw new Error('$name must be <= $max');"$'\n'
  fi

  if [[ "$format" == "email" ]]; then
    validation_lines+="  if (data.$name && !/^\\S+@\\S+\\.\\S+$/.test(data.$name)) throw new Error('$name must be a valid email');"$'\n'
  fi

  if [[ "$format" == "time" ]]; then
    validation_lines+="  if (data.$name && !/^\\d{2}:\\d{2}$/.test(data.$name)) throw new Error('$name must be in HH:MM format');"$'\n'
  fi

  if [[ "$enum" != "" && "$enum" != "null" ]]; then
    validation_lines+="  if (data.$name && !$(echo "$enum")?.includes(data.$name)) throw new Error('$name must be one of: $(echo "$enum" | jq -r '. | join(\", \")')');"$'\n'
  fi
done

cat <<EOF >"$validate_file"
export function validate${EntityPascal}(data) {
$validation_lines  return true;
}
EOF

echo "✅ Validación generada: $validate_file"
