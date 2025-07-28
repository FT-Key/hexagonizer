#!/bin/bash
# generator/entity/03-generate-domain.sh
# shellcheck disable=SC2154
set -e

# ==========================================
# COLORES Y FUNCIONES DE LOG (locales)
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

# ==========================================
# RUTA Y ARCHIVO DE DESTINO
# ==========================================
DOMAIN_PATH="src/domain/$entity"
domain_file="$DOMAIN_PATH/${entity}.js"

# ==========================================
# FUNCIONES DE GENERACIÓN
# ==========================================

setup_domain_directory() {
  log "INFO" "📁 Creando carpeta: $DOMAIN_PATH"
  mkdir -p "$DOMAIN_PATH"
}

extract_field_data() {
  log "INFO" "📦 Procesando campos definidos en el esquema"
  eval "$(echo "$PARSED_FIELDS" | node -e "
    const input = JSON.parse(require('fs').readFileSync(0, 'utf8'));
    const { fields, methods } = input;

    const printArray = (name, arr) => {
      arr.forEach((v, i) => {
        const safe = (v ?? '').toString().replace(/'/g, \"'\\\\''\");
        console.log(\`\${name}[\${i}]='\${safe}'\`);
      });
    };

    printArray('field_names', fields.map(f => f.name));
    printArray('field_defaults', fields.map(f => f.default ?? ''));
    printArray('field_requireds', fields.map(f => f.required ? 'true' : 'false'));
    printArray('method_names', methods.map(m => m.name));
    printArray('method_params', methods.map(m => JSON.stringify(m.params)));
    printArray('method_bodies', methods.map(m => m.body));
  ")"
}

build_constructor() {
  constructor_params=""
  declare -ga constructor_body_lines=()

  for i in "${!field_names[@]}"; do
    local name="${field_names[i]}"
    local default="${field_defaults[i]}"
    local required="${field_requireds[i]}"

    constructor_params+="${constructor_params:+, }$name"

    if [[ "$required" == "true" && -z "$default" ]]; then
      constructor_body_lines+=("    if ($name === undefined) throw new Error('$name is required');")
      constructor_body_lines+=("    this._$name = $name;")
    elif [[ -n "$default" ]]; then
      if [[ "$default" =~ ^\".*\"$ ]]; then
        local default_value="${default:1:-1}"
        constructor_body_lines+=("    this._$name = $name !== undefined ? $name : \"$default_value\";")
      else
        constructor_body_lines+=("    this._$name = $name !== undefined ? $name : $default;")
      fi
    else
      constructor_body_lines+=("    this._$name = $name;")
    fi
  done
}

build_accessors() {
  declare -ga getter_lines=() setter_lines=() tojson_lines=()

  for i in "${!field_names[@]}"; do
    local name="${field_names[i]}"
    getter_lines+=("  get $name() { return this._$name; }")
    setter_lines+=("  set $name(value) { this._$name = value; this._touchUpdatedAt(); }")
    tojson_lines+=("      $name: this._$name,")
  done

  [[ ${#tojson_lines[@]} -gt 0 ]] && tojson_lines[-1]="${tojson_lines[-1]%,}"
}

build_methods() {
  declare -ga method_lines=()

  if [[ ${#method_names[@]} -eq 0 ]]; then
    method_lines+=("")
  else
    for i in "${!method_names[@]}"; do
      local params=$(echo "${method_params[i]}" | jq -r '. | join(", ")')
      method_lines+=("")
      method_lines+=("  ${method_names[i]}($params) {")
      method_lines+=("    ${method_bodies[i]}")
      method_lines+=("  }")
    done
  fi
}

confirm_file_overwrite() {
  if [[ -f "$domain_file" && "$AUTO_CONFIRM" != true ]]; then
    printf "${YELLOW}⚠️  El archivo %s ya existe. ¿Desea sobrescribirlo? [s/N]: ${NC}" "$domain_file"
    read -r confirm
    if [[ ! "$confirm" =~ ^[Ss]$ ]]; then
      log "INFO" "⏭️  Clase omitida: $domain_file"
      exit 0
    fi
  fi
}

write_domain_class() {
  log "INFO" "📝 Escribiendo clase de dominio en: $domain_file"
  cat >"$domain_file" <<EOF
export class $EntityPascal {
  /**
   * @param {Object} params
   */
  constructor({ $constructor_params }) {
$(printf '%s\n' "${constructor_body_lines[@]}")
  }

$(printf '%s\n' "${getter_lines[@]}")
$(printf '%s\n' "${setter_lines[@]}")

  activate() {
    this._active = true;
    this._touchUpdatedAt();
  }

  deactivate() {
    this._active = false;
    this._touchUpdatedAt();
  }

  _touchUpdatedAt() {
    this._updatedAt = new Date();
  }
$(printf '%s\n' "${method_lines[@]}")

  toJSON() {
    return {
$(printf '%s\n' "${tojson_lines[@]}")
    };
  }
}
EOF
}

# ==========================================
# EJECUCIÓN
# ==========================================

log "INFO" "=== GENERADOR DE DOMINIO ==="
log "INFO" "Entidad: $entity ($EntityPascal)"
log "INFO" "Auto-confirmación: ${AUTO_CONFIRM:-false}"
echo ""

setup_domain_directory
extract_field_data
build_constructor
build_accessors
build_methods
confirm_file_overwrite
write_domain_class

log "SUCCESS" "✅ Clase generada: $domain_file"
