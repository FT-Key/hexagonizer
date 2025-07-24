#!/bin/bash
# shellcheck disable=SC2154
# 1. DOMAIN
ENTITY_PASCAL="$(tr '[:lower:]' '[:upper:]' <<<"${entity:0:1}")${entity:1}"
DOMAIN_PATH="src/domain/$entity"
mkdir -p "$DOMAIN_PATH"
domain_file="$DOMAIN_PATH/${entity}.js"

# Campos genéricos reservados que no deben salir de los fields JSON
GENERIC_FIELDS=("id" "active" "createdAt" "updatedAt" "deletedAt" "ownedBy")

# Función para saber si un valor está en un array (case sensitive)
contains() {
  local e match="$1"
  shift
  for e; do [[ "$e" == "$match" ]] && return 0; done
  return 1
}

# Método más robusto para construir los arrays
declare -a names
declare -a defaults
declare -a requireds

# Obtener la cantidad de campos
field_count=$(echo "$fields" | jq '. | length')

# Llenar arrays campo por campo, ignorando campos genéricos
for ((i = 0; i < field_count; i++)); do
  name=$(echo "$fields" | jq -r ".[$i].name")
  # Ignorar campos genéricos
  if contains "$name" "${GENERIC_FIELDS[@]}"; then
    continue
  fi
  names+=("$name")
  defaults+=("$(echo "$fields" | jq -r ".[$i].default // empty")")
  requireds+=("$(echo "$fields" | jq -r ".[$i].required // false")")
done

# Procesar métodos si existen - CORREGIDO
declare -a method_lines
if echo "$schema_content" | jq -e '.methods' >/dev/null 2>&1; then
  method_count=$(echo "$schema_content" | jq '.methods | length')

  for ((i = 0; i < method_count; i++)); do
    method_name=$(echo "$schema_content" | jq -r ".methods[$i].name")
    method_params=$(echo "$schema_content" | jq -r ".methods[$i].params | join(\", \")")
    method_body=$(echo "$schema_content" | jq -r ".methods[$i].body")

    # Construir el método
    method_lines+=("") # línea vacía antes del método
    method_lines+=("  $method_name($method_params) {")
    method_lines+=("    $method_body")
    method_lines+=("  }")
  done
fi

constructor_params=""
declare -a constructor_body_lines
declare -a getter_lines
declare -a setter_lines
declare -a tojson_lines

# Primero, agregar campos genéricos con lógica fija

constructor_params+="id, active = true, createdAt = new Date(), updatedAt = new Date(), deletedAt = null, ownedBy = null"

constructor_body_lines+=("    if (id === undefined) throw new Error('id is required');")
constructor_body_lines+=("    this._id = id;")
constructor_body_lines+=("    this._active = active;")
constructor_body_lines+=("    this._createdAt = createdAt;")
constructor_body_lines+=("    this._updatedAt = updatedAt;")
constructor_body_lines+=("    this._deletedAt = deletedAt;")
constructor_body_lines+=("    this._ownedBy = ownedBy;")

getter_lines+=("  get id() { return this._id; }")
setter_lines+=("  set id(value) { this._id = value; this._touchUpdatedAt(); }")

getter_lines+=("  get active() { return this._active; }")
setter_lines+=("  set active(value) { this._active = value; this._touchUpdatedAt(); }")

getter_lines+=("  get createdAt() { return this._createdAt; }")
setter_lines+=("  set createdAt(value) { this._createdAt = value; this._touchUpdatedAt(); }")

getter_lines+=("  get updatedAt() { return this._updatedAt; }")
setter_lines+=("  set updatedAt(value) { this._updatedAt = value; this._touchUpdatedAt(); }")

getter_lines+=("  get deletedAt() { return this._deletedAt; }")
setter_lines+=("  set deletedAt(value) { this._deletedAt = value; this._touchUpdatedAt(); }")

getter_lines+=("  get ownedBy() { return this._ownedBy; }")
setter_lines+=("  set ownedBy(value) { this._ownedBy = value; this._touchUpdatedAt(); }")

tojson_lines+=("      id: this._id,")
tojson_lines+=("      active: this._active,")
tojson_lines+=("      createdAt: this._createdAt,")
tojson_lines+=("      updatedAt: this._updatedAt,")
tojson_lines+=("      deletedAt: this._deletedAt,")
tojson_lines+=("      ownedBy: this._ownedBy,")

# Ahora agregamos los campos custom (no genéricos)

for i in "${!names[@]}"; do
  name="${names[i]}"
  default="${defaults[i]}"
  required="${requireds[i]}"

  constructor_params+=", $name"

  if [[ "$required" == "true" && (-z "$default" || "$default" == "empty") ]]; then
    constructor_body_lines+=("    if ($name === undefined) throw new Error('$name is required');")
    constructor_body_lines+=("    this._$name = $name;")
  elif [[ -n "$default" && "$default" != "empty" ]]; then
    constructor_body_lines+=("    this._$name = $name !== undefined ? $name : $default;")
  else
    constructor_body_lines+=("    this._$name = $name;")
  fi

  getter_lines+=("  get $name() { return this._$name; }")
  setter_lines+=("  set $name(value) { this._$name = value; this._touchUpdatedAt(); }")
  tojson_lines+=("      $name: this._$name,")
done

# Limpiar última coma del toJSON
if [[ ${#tojson_lines[@]} -gt 0 ]]; then
  tojson_lines[-1]="${tojson_lines[-1]%,}"
fi

if [[ -f "$domain_file" && "$AUTO_CONFIRM" != true ]]; then
  read -r -p "⚠️  El archivo $domain_file ya existe. ¿Desea sobrescribirlo? [y/n]: " confirm
  if [[ ! "$confirm" =~ ^[Yy]$ ]]; then
    echo "⏭️  Se omitió la escritura de $domain_file"
    exit 0
  fi
fi

# Escritura del archivo
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
  echo ""

  # Agregar métodos personalizados si existen
  if [[ ${#method_lines[@]} -gt 0 ]]; then
    printf "%s\n" "${method_lines[@]}"
  fi

  echo ""
  echo "  toJSON() {"
  echo "    return {"
  printf "%s\n" "${tojson_lines[@]}"
  echo "    };"
  echo "  }"
  echo "}"
} >"$domain_file"

echo "✅ Clase generada: $domain_file"
