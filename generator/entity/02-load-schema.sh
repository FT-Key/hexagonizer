#!/bin/bash
# generator/entity/02-load-schema.sh
# shellcheck disable=SC2034,SC2154
set -e

source "$PROJECT_ROOT/generator/common/logging.sh"
source "$PROJECT_ROOT/generator/common/io.sh"

# ========================
# CONFIGURATION
# ========================
readonly SCHEMA_DIR="./entity-schemas"

# ========================
# UTILITY FUNCTIONS
# ========================

# Check if a directory exists
directory_exists() {
  [[ -d "$1" ]]
}

# Check if a file exists
file_exists() {
  [[ -f "$1" ]]
}

# Create directory if it doesn't exist
ensure_directory_exists() {
  local dir="$1"

  if ! directory_exists "$dir"; then
    log "INFO" "Creating directory: $dir"
    if mkdir -p "$dir"; then
      log "SUCCESS" "Directory created: $dir"
    else
      log "ERROR" "Error creating directory: $dir"
      return 1
    fi
  else
    log "DEBUG" "Directory already exists: $dir"
  fi
}

# Validate number within range
validate_number_range() {
  local input="$1"
  local min="$2"
  local max="$3"

  [[ "$input" =~ ^[0-9]+$ ]] && ((input >= min && input <= max))
}

# ========================
# SCHEMA LOADING FUNCTIONS
# ========================

# Mostrar archivos JSON disponibles
display_available_schemas() {
  local json_files=("$@")

  log "INFO" "Available schema files:"
  for i in "${!json_files[@]}"; do
    local filename
    filename=$(basename "${json_files[i]}")
    printf "  ${CYAN}%d)${NC} %s\n" "$((i + 1))" "$filename"
  done
}

# Obtener archivos JSON del directorio
get_json_files() {
  local -n json_files_ref=$1

  log "INFO" "Looking for JSON files in: $SCHEMA_DIR"

  mapfile -t json_files_ref < <(find "$SCHEMA_DIR" -maxdepth 1 -type f -name '*.json' | sort)

  if [[ ${#json_files_ref[@]} -eq 0 ]]; then
    log "ERROR" "No JSON files found in $SCHEMA_DIR"
    return 1
  fi

  log "SUCCESS" "Found ${#json_files_ref[@]} JSON file(s)"
}

# Prompt file selection
prompt_file_selection() {
  local -n json_files_ref=$1
  local selected_num

  display_available_schemas "${json_files_ref[@]}"

  log "INPUT" "Select the JSON file to use"
  read -r -p "Enter number (1-${#json_files_ref[@]}): " selected_num

  if ! validate_number_range "$selected_num" 1 "${#json_files_ref[@]}"; then
    log "ERROR" "Invalid selection: $selected_num"
    return 1
  fi

  SCHEMA_FILE="${json_files_ref[selected_num - 1]}"
  log "SUCCESS" "Selected file: $(basename "$SCHEMA_FILE")"
}

# Cargar esquema desde archivo JSON
load_schema_from_json() {
  log "INFO" "Iniciando carga de esquema desde JSON"

  log "INPUT" "Enter path to the entity schema JSON file"
  echo "   (or press Enter to list available files in $SCHEMA_DIR):"
  read -r input_path

  if [[ -z "$input_path" ]]; then
    log "INFO" "No path specified, listing available files"

    ensure_directory_exists "$SCHEMA_DIR" || return 1

    local json_files
    get_json_files json_files || return 1

    prompt_file_selection json_files || return 1
  else
    log "INFO" "Verifying specified file: $input_path"

    if ! file_exists "$input_path"; then
      log "ERROR" "JSON file not found: $input_path"
      return 1
    fi

    SCHEMA_FILE="$input_path"
    log "SUCCESS" "JSON file found: $input_path"
  fi

  log "INFO" "Loading schema content..."
  if SCHEMA_CONTENT=$(cat "$SCHEMA_FILE"); then
    ENTITY_NAME=$(basename "$SCHEMA_FILE" .json | tr '[:upper:]' '[:lower:]')
    log "SUCCESS" "Schema loaded successfully for entity: $ENTITY_NAME"
  else
    log "ERROR" "Error reading schema file: $SCHEMA_FILE"
    return 1
  fi
}

# Crear esquema por defecto
create_default_schema() {
  log "INFO" "Creating default schema"

  if [[ -z "$ENTITY_NAME" ]]; then
    log "INPUT" "Enter the entity name"
    read -r -p "Entity name (e.g. user, product): " entity_input
    entity_input="${entity_input,,}"
  else
    entity_input="$ENTITY_NAME"
    log "INFO" "Entity name received: $entity_input"
  fi

  if [[ -z "$entity_input" ]]; then
    log "ERROR" "Entity name cannot be empty"
    return 1
  fi

  ENTITY_NAME="$entity_input"
  log "SUCCESS" "Entity name set: $ENTITY_NAME"

  log "INFO" "Generating default schema..."
  SCHEMA_CONTENT=$(
    cat <<EOF
{
  "name": "$ENTITY_NAME",
  "fields": [
    { "name": "id", "required": true },
    { "name": "active", "default": true },
    { "name": "createdAt", "default": "new Date()" },
    { "name": "updatedAt", "default": "new Date()" },
    { "name": "deletedAt", "default": null, "sensitive": true },
    { "name": "ownedBy", "default": null, "sensitive": true }
  ],
  "methods": []
}
EOF
  )
  SCHEMA_FILE=""
  log "SUCCESS" "Default schema created"
}

# ========================
# VALIDATION FUNCTIONS
# ========================

# Validar nombre de entidad
validate_entity_name() {
  log "INFO" "Validating entity name: $ENTITY_NAME"

  local clean_name
  clean_name=$(echo "$ENTITY_NAME" | sed 's/^[[:space:]]*//;s/[[:space:]]*$//' | tr -cd '[:alnum:]')

  if [[ -z "$clean_name" ]]; then
    log "ERROR" "Entity name cannot be empty or contain invalid characters"
    return 1
  fi

  entity="$clean_name"
  EntityPascal="$(tr '[:lower:]' '[:upper:]' <<<"${clean_name:0:1}")${clean_name:1}"

  log "SUCCESS" "Entity name validated - snake_case: $entity, PascalCase: $EntityPascal"
}

# ========================
# SCHEMA PARSING FUNCTIONS
# ========================

# Parsear campos del esquema
parse_schema_fields() {
  log "INFO" "Starting schema field parsing"

  local parser_script="$PROJECT_ROOT/generator/utils/parse-schema-fields.js"

  if ! file_exists "$parser_script"; then
    log "ERROR" "Schema parser not found: $parser_script"
    return 1
  fi

  if [[ -n "$SCHEMA_FILE" ]]; then
    log "INFO" "Parsing from file: $SCHEMA_FILE"
    if PARSED_FIELDS=$(node "$parser_script" "$SCHEMA_FILE"); then
      log "SUCCESS" "Fields parsed from file successfully"
    else
      log "ERROR" "Error parsing fields from file"
      return 1
    fi
  elif [[ -n "$SCHEMA_CONTENT" ]]; then
    log "INFO" "Parsing from in-memory content"
    if PARSED_FIELDS=$(echo "$SCHEMA_CONTENT" | node "$parser_script"); then
      log "SUCCESS" "Fields parsed from content successfully"
    else
      log "ERROR" "Error parsing fields from content"
      return 1
    fi
  else
    log "ERROR" "Cannot generate fields: no schema available"
    return 1
  fi

  log "DEBUG" "Parsed fields stored in PARSED_FIELDS variable"
}

# ========================
# EXPORT FUNCTIONS
# ========================

# Exportar variables para otros scripts
export_schema_variables() {
  log "INFO" "Exporting schema variables for other scripts"

  export entity EntityPascal SCHEMA_FILE SCHEMA_CONTENT PARSED_FIELDS

  log "DEBUG" "Exported variables:"
  log "DEBUG" "  - entity: $entity"
  log "DEBUG" "  - EntityPascal: $EntityPascal"
  log "DEBUG" "  - SCHEMA_FILE: ${SCHEMA_FILE:-'(empty)'}"
  log "DEBUG" "  - has_json: ${has_json:-'false'}"
}

# ========================
# MAIN FUNCTION
# ========================
main() {
  log "INFO" "Starting entity schema loading"

  # Determine load mode based on USE_JSON
  if [[ "$USE_JSON" == true ]]; then
    log "INFO" "JSON mode enabled, loading from file"
    if load_schema_from_json; then
      export has_json=true
      log "SUCCESS" "JSON schema loaded successfully"
    else
      log "ERROR" "Error loading JSON schema"
      return 1
    fi
  else
    log "INFO" "Default mode active, creating standard schema"
    if create_default_schema; then
      export has_json=false
      log "SUCCESS" "Default schema created successfully"
    else
      log "ERROR" "Error creating default schema"
      return 1
    fi
  fi

  # Validar y procesar
  validate_entity_name || return 1
  parse_schema_fields || return 1
  export_schema_variables

  log "SUCCESS" "Schema loading completed - Entity: $entity ($EntityPascal)"
}

# ========================
# EXECUTION LOGIC
# ========================
# If called directly with bash
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
  main "$@"
fi

# If sourced and specific conditions exist
if [[ "${BASH_SOURCE[0]}" != "${0}" && (-n "${CREATE_QUERY_UTILS:-}" || $# -gt 0) ]]; then
  main "$@"
fi
