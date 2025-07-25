#!/bin/bash
# generator/entity/03-generate-domain.sh
# shellcheck disable=SC2154
set -e

ENTITY_PASCAL="$(tr '[:lower:]' '[:upper:]' <<<"${entity:0:1}")${entity:1}"
DOMAIN_PATH="src/domain/$entity"
domain_file="$DOMAIN_PATH/${entity}.js"
mkdir -p "$DOMAIN_PATH"

PROJECT_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"

if [[ -n "$SCHEMA_FILE" ]]; then
  # Usar archivo físico para parsear
  parsed_json=$(node "$PROJECT_ROOT/generator/utils/parse-schema-fields.js" "$SCHEMA_FILE")
elif [[ -n "$SCHEMA_CONTENT" ]]; then
  # Usar JSON en memoria
  parsed_json=$(echo "$SCHEMA_CONTENT" | node "$PROJECT_ROOT/generator/utils/parse-schema-fields.js")
else
  echo "❌ No hay esquema definido para parsear en domain"
  exit 1
fi

# === Convertir JSON a variables Bash con node ===
# Usamos node para imprimir arrays exportables desde Bash
eval "$(echo "$parsed_json" | node -e "
  const input = JSON.parse(require('fs').readFileSync(0, 'utf8'));
  const fields = input.fields;
  const methods = input.methods;

  const printArray = (name, arr) => {
    arr.forEach((v, i) => {
      // Escapar comillas simples para bash
      const safe = v === undefined ? '' : v.toString().replace(/'/g, \"'\\\\''\");
      console.log(\`\${name}[\${i}]='\${safe}'\`);
    });
  };

  printArray('names', fields.map(f => f.name));
  printArray('defaults', fields.map(f => f.default ?? ''));
  printArray('requireds', fields.map(f => f.required ? 'true' : 'false'));

  printArray('method_names', methods.map(m => m.name));
  printArray('method_params', methods.map(m => JSON.stringify(m.params)));
  printArray('method_bodies', methods.map(m => m.body));
")"

# === Preparar generación de clase ===

constructor_params=""
declare -a constructor_body_lines=()
declare -a getter_lines=()
declare -a setter_lines=()
declare -a tojson_lines=()

for i in "${!names[@]}"; do
  name="${names[i]}"
  default="${defaults[i]}"
  required="${requireds[i]}"

  # Construir lista de parámetros del constructor
  if [[ -z "$constructor_params" ]]; then
    constructor_params="$name"
  else
    constructor_params+=", $name"
  fi

  # Validar si es requerido y sin default
  if [[ "$required" == "true" && -z "$default" ]]; then
    constructor_body_lines+=("    if ($name === undefined) throw new Error('$name is required');")
    constructor_body_lines+=("    this._$name = $name;")
  elif [[ -n "$default" ]]; then
    if [[ "$default" =~ ^\".*\"$ ]]; then
      # Es un string JSON, quitar las comillas externas para asignar con comillas explícitas
      default_value="${default:1:-1}"
      constructor_body_lines+=("    this._$name = $name !== undefined ? $name : \"$default_value\";")
    else
      # Es número, booleano, array, objeto, etc.
      constructor_body_lines+=("    this._$name = $name !== undefined ? $name : $default;")
    fi
  else
    constructor_body_lines+=("    this._$name = $name;")
  fi

  # Getters y setters
  getter_lines+=("  get $name() { return this._$name; }")
  setter_lines+=("  set $name(value) { this._$name = value; this._touchUpdatedAt(); }")

  # toJSON properties
  tojson_lines+=("      $name: this._$name,")
done

# Quitar la coma final del último campo en toJSON
if [[ ${#tojson_lines[@]} -gt 0 ]]; then
  tojson_lines[-1]="${tojson_lines[-1]%,}"
fi

# Agregar métodos
declare -a method_lines=()
if [[ ${#method_names[@]} -eq 0 ]]; then
  method_lines+=(" ")
else
  for i in "${!method_names[@]}"; do
    # Params vienen como JSON array, quitar comillas para imprimir limpio
    params=$(echo "${method_params[i]}" | jq -r '. | join(", ")')
    method_lines+=("")
    method_lines+=("  ${method_names[i]}($params) {")
    method_lines+=("    ${method_bodies[i]}")
    method_lines+=("  }")
  done
fi

# Confirmación de escritura
if [[ -f "$domain_file" && "$AUTO_CONFIRM" != true ]]; then
  read -r -p "⚠️  El archivo $domain_file ya existe. ¿Desea sobrescribirlo? [y/n]: " confirm
  if [[ ! "$confirm" =~ ^[Yy]$ ]]; then
    echo "⏭️  Se omitió la escritura de $domain_file"
    exit 0
  fi
fi

# === Escritura del archivo final ===
{
  echo "export class $ENTITY_PASCAL {"
  echo "  /**"
  echo "   * @param {Object} params"
  echo "   */"
  echo "  constructor({ $constructor_params }) {"
  printf "%s\n" "${constructor_body_lines[@]}"
  echo "  }"
  echo ""
  printf "%s\n" "${getter_lines[@]}"
  printf "%s\n" "${setter_lines[@]}"
  echo ""
  echo "  activate() {"
  echo "    this._active = true;"
  echo "    this._touchUpdatedAt();"
  echo "  }"
  echo ""
  echo "  deactivate() {"
  echo "    this._active = false;"
  echo "    this._touchUpdatedAt();"
  echo "  }"
  echo ""
  echo "  _touchUpdatedAt() {"
  echo "    this._updatedAt = new Date();"
  echo "  }"
  printf "%s\n" "${method_lines[@]}"
  echo ""
  echo "  toJSON() {"
  echo "    return {"
  printf "%s\n" "${tojson_lines[@]}"
  echo "    };"
  echo "  }"
  echo "}"
} >"$domain_file"

echo "✅ Clase generada: $domain_file"
