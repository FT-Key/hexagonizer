#!/bin/bash
# generator/entity/04-generate-validation.sh
# shellcheck disable=SC2154
set -e

# ==========================================
# COLORES Y LOGGING (inline, no modularizado aún)
# ==========================================
if [[ -z "${RED:-}" ]]; then
  readonly RED='\033[0;31m'
  readonly GREEN='\033[0;32m'
  readonly YELLOW='\033[1;33m'
  readonly BLUE='\033[0;34m'
  readonly NC='\033[0m' # No Color
fi

log() {
  local level="$1"
  shift
  local message="$*"
  local timestamp
  timestamp=$(date '+%Y-%m-%d %H:%M:%S')

  case "$level" in
  "INFO") printf "${BLUE}[INFO]${NC} %s: %s\n" "$timestamp" "$message" ;;
  "WARN") printf "${YELLOW}[WARN]${NC} %s: %s\n" "$timestamp" "$message" ;;
  "ERROR") printf "${RED}[ERROR]${NC} %s: %s\n" "$timestamp" "$message" >&2 ;;
  "SUCCESS") printf "${GREEN}[SUCCESS]${NC} %s: %s\n" "$timestamp" "$message" ;;
  esac
}

confirm_overwrite() {
  local file_path="$1"
  local file_type="${2:-archivo}"
  local auto_confirm="${AUTO_CONFIRM:-false}"

  if [[ -e "$file_path" && "$auto_confirm" != "true" ]]; then
    printf "${YELLOW}⚠️  El %s %s ya existe. ¿Deseas sobrescribirlo? [s/N]: ${NC}" "$file_type" "$file_path"
    read -r confirm
    if [[ ! "$confirm" =~ ^[Ss]$ ]]; then
      log "INFO" "⏭️  Omitido: $file_path"
      return 1
    fi
  fi
  return 0
}

# ==========================================
# GENERADOR DE VALIDACIÓN
# ==========================================

validate_file="src/domain/$entity/validate-$entity.js"

extract_validation_data() {
  log "INFO" "Extrayendo validaciones del esquema JSON..."
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
  log "INFO" "Campos analizados: ${#v_names[@]}"
}

build_field_validation() {
  local name="$1" required="$2" type="$3" enum="$4" enum_display="$5"
  local format="$6" minLength="$7" maxLength="$8" min="$9" max="${10}" nullable="${11}"
  local field_lines=""

  [[ -z "$name" || "$name" == "null" ]] && return

  if [[ "$required" == "true" && "$nullable" != "true" ]]; then
    field_lines+="  if (data.$name === undefined || data.$name === null) throw new Error('$name is required');"$'\n'
  fi

  case "$type" in
  string | number | boolean | object)
    field_lines+="  if (data.$name != null && typeof data.$name !== '$type') throw new Error('$name must be a $type');"$'\n'
    ;;
  esac

  [[ -n "$minLength" ]] && field_lines+="  if (data.$name && data.$name.length < $minLength) throw new Error('$name must have at least $minLength characters');"$'\n'
  [[ -n "$maxLength" ]] && field_lines+="  if (data.$name && data.$name.length > $maxLength) throw new Error('$name must have at most $maxLength characters');"$'\n'

  [[ -n "$min" ]] && field_lines+="  if (data.$name < $min) throw new Error('$name must be >= $min');"$'\n'
  [[ -n "$max" ]] && field_lines+="  if (data.$name > $max) throw new Error('$name must be <= $max');"$'\n'

  case "$format" in
  email) field_lines+="  if (data.$name && !/^\\S+@\\S+\\.\\S+$/.test(data.$name)) throw new Error('$name must be a valid email');"$'\n' ;;
  time) field_lines+="  if (data.$name && !/^\\d{2}:\\d{2}$/.test(data.$name)) throw new Error('$name must be in HH:MM format');"$'\n' ;;
  esac

  if [[ -n "$enum" ]]; then
    IFS=',' read -r -a enum_array <<<"$enum"
    local enum_js="["
    for val in "${enum_array[@]}"; do enum_js+="'$val',"; done
    enum_js="${enum_js%,}]"
    field_lines+="  if (data.$name && !$enum_js.includes(data.$name)) throw new Error('$name must be one of: $enum_display');"$'\n'
  fi

  if [[ -n "$field_lines" ]]; then
    [[ -n "$validation_lines" ]] && validation_lines+=$'\n'
    validation_lines+="$field_lines"
  fi
}

build_validations() {
  log "INFO" "Generando reglas de validación..."
  validation_lines=""

  for i in "${!v_names[@]}"; do
    build_field_validation \
      "${v_names[$i]}" "${v_requireds[$i]}" "${v_types[$i]}" "${v_enums[$i]}" \
      "${v_enumDisplays[$i]}" "${v_formats[$i]}" "${v_minLengths[$i]}" \
      "${v_maxLengths[$i]}" "${v_mins[$i]}" "${v_maxs[$i]}" "${v_nullables[$i]}"
  done
}

write_validation_file() {
  cat >"$validate_file" <<EOF
export function validate${EntityPascal}(data) {
$validation_lines
  return true;
}
EOF
}

# ==========================================
# EJECUCIÓN PRINCIPAL
# ==========================================

log "INFO" "=== GENERADOR DE VALIDACIONES ==="
log "INFO" "Entidad: $entity ($EntityPascal)"
log "INFO" "Auto-confirmación: ${AUTO_CONFIRM:-false}"
echo ""

extract_validation_data
build_validations

if confirm_overwrite "$validate_file" "archivo de validación"; then
  write_validation_file
  log "SUCCESS" "✅ Validación generada: $validate_file"
else
  log "INFO" "⏭️  Validación omitida: $validate_file"
fi
