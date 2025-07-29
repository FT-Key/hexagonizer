#!/bin/bash
# generator/entity/02-load-schema.sh
# shellcheck disable=SC2034,SC2154
set -e

# ========================
# COLORES PARA OUTPUT
# ========================
if [[ -z "${RED:-}" ]]; then
  readonly RED='\033[0;31m'
  readonly GREEN='\033[0;32m'
  readonly YELLOW='\033[1;33m'
  readonly BLUE='\033[0;34m'
  readonly CYAN='\033[0;36m'
  readonly MAGENTA='\033[0;35m'
  readonly NC='\033[0m' # No Color
fi

# ========================
# LOGGING FUNCTION
# ========================
log() {
  local level="$1"
  shift
  local message="$*"
  local timestamp
  timestamp=$(date '+%Y-%m-%d %H:%M:%S')

  case "$level" in
  "INFO") printf "${BLUE}[INFO]${NC}    %s - %s\n" "$timestamp" "$message" ;;
  "SUCCESS") printf "${GREEN}[SUCCESS]${NC} %s - %s\n" "$timestamp" "$message" ;;
  "WARN") printf "${YELLOW}[WARN]${NC}    %s - %s\n" "$timestamp" "$message" ;;
  "ERROR") printf "${RED}[ERROR]${NC}   %s - %s\n" "$timestamp" "$message" >&2 ;;
  "INPUT") printf "${CYAN}[INPUT]${NC}   %s - %s\n" "$timestamp" "$message" ;;
  "DEBUG") printf "${MAGENTA}[DEBUG]${NC}   %s - %s\n" "$timestamp" "$message" ;;
  esac
}

# ========================
# CONFIGURATION
# ========================
readonly SCHEMA_DIR="./entity-schemas"

# ========================
# UTILITY FUNCTIONS
# ========================

# Función para verificar si un directorio existe
directory_exists() {
  [[ -d "$1" ]]
}

# Función para verificar si un archivo existe
file_exists() {
  [[ -f "$1" ]]
}

# Función para crear directorio si no existe
ensure_directory_exists() {
  local dir="$1"

  if ! directory_exists "$dir"; then
    log "INFO" "Creando directorio: $dir"
    if mkdir -p "$dir"; then
      log "SUCCESS" "Directorio creado: $dir"
    else
      log "ERROR" "Error creando directorio: $dir"
      return 1
    fi
  else
    log "DEBUG" "Directorio ya existe: $dir"
  fi
}

# Función para validar número dentro de rango
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

  log "INFO" "Archivos de esquema disponibles:"
  for i in "${!json_files[@]}"; do
    local filename
    filename=$(basename "${json_files[i]}")
    printf "  ${CYAN}%d)${NC} %s\n" "$((i + 1))" "$filename"
  done
}

# Obtener archivos JSON del directorio
get_json_files() {
  local -n json_files_ref=$1

  log "INFO" "Buscando archivos JSON en: $SCHEMA_DIR"

  mapfile -t json_files_ref < <(find "$SCHEMA_DIR" -maxdepth 1 -type f -name '*.json' | sort)

  if [[ ${#json_files_ref[@]} -eq 0 ]]; then
    log "ERROR" "No se encontraron archivos JSON en $SCHEMA_DIR"
    return 1
  fi

  log "SUCCESS" "Encontrados ${#json_files_ref[@]} archivo(s) JSON"
}

# Solicitar selección de archivo al usuario
prompt_file_selection() {
  local -n json_files_ref=$1
  local selected_num

  display_available_schemas "${json_files_ref[@]}"

  log "INPUT" "Seleccione el archivo JSON para usar"
  read -r -p "Ingrese número (1-${#json_files_ref[@]}): " selected_num

  if ! validate_number_range "$selected_num" 1 "${#json_files_ref[@]}"; then
    log "ERROR" "Selección inválida: $selected_num"
    return 1
  fi

  SCHEMA_FILE="${json_files_ref[selected_num - 1]}"
  log "SUCCESS" "Archivo seleccionado: $(basename "$SCHEMA_FILE")"
}

# Cargar esquema desde archivo JSON
load_schema_from_json() {
  log "INFO" "Iniciando carga de esquema desde JSON"

  log "INPUT" "Ingrese ruta al archivo JSON de esquema de entidad"
  echo "   (o presione Enter para listar archivos disponibles en $SCHEMA_DIR):"
  read -r input_path

  if [[ -z "$input_path" ]]; then
    log "INFO" "No se especificó ruta, listando archivos disponibles"

    ensure_directory_exists "$SCHEMA_DIR" || return 1

    local json_files
    get_json_files json_files || return 1

    prompt_file_selection json_files || return 1
  else
    log "INFO" "Verificando archivo especificado: $input_path"

    if ! file_exists "$input_path"; then
      log "ERROR" "No se encontró el archivo JSON: $input_path"
      return 1
    fi

    SCHEMA_FILE="$input_path"
    log "SUCCESS" "Archivo JSON encontrado: $input_path"
  fi

  log "INFO" "Cargando contenido del esquema..."
  if SCHEMA_CONTENT=$(cat "$SCHEMA_FILE"); then
    ENTITY_NAME=$(basename "$SCHEMA_FILE" .json | tr '[:upper:]' '[:lower:]')
    log "SUCCESS" "Esquema cargado exitosamente para entidad: $ENTITY_NAME"
  else
    log "ERROR" "Error leyendo archivo de esquema: $SCHEMA_FILE"
    return 1
  fi
}

# Crear esquema por defecto
create_default_schema() {
  log "INFO" "Creando esquema por defecto"

  log "INPUT" "Ingrese el nombre de la entidad"
  read -r -p "📝 Nombre de la entidad (ej. user, product): " entity

  if [[ -z "$entity" ]]; then
    log "ERROR" "El nombre de la entidad no puede estar vacío"
    return 1
  fi

  ENTITY_NAME="${entity,,}"
  log "SUCCESS" "Nombre de entidad establecido: $ENTITY_NAME"

  log "INFO" "Generando esquema por defecto..."
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
  log "SUCCESS" "Esquema por defecto creado"
}

# ========================
# VALIDATION FUNCTIONS
# ========================

# Validar nombre de entidad
validate_entity_name() {
  log "INFO" "Validando nombre de entidad: $ENTITY_NAME"

  local clean_name
  clean_name=$(echo "$ENTITY_NAME" | sed 's/^[[:space:]]*//;s/[[:space:]]*$//' | tr -cd '[:alnum:]')

  if [[ -z "$clean_name" ]]; then
    log "ERROR" "El nombre de la entidad no puede estar vacío o contener caracteres inválidos"
    return 1
  fi

  entity="$clean_name"
  EntityPascal="$(tr '[:lower:]' '[:upper:]' <<<"${clean_name:0:1}")${clean_name:1}"

  log "SUCCESS" "Nombre de entidad validado - snake_case: $entity, PascalCase: $EntityPascal"
}

# ========================
# SCHEMA PARSING FUNCTIONS
# ========================

# Parsear campos del esquema
parse_schema_fields() {
  log "INFO" "Iniciando parsing de campos del esquema"

  local parser_script="$PROJECT_ROOT/generator/utils/parse-schema-fields.js"

  if ! file_exists "$parser_script"; then
    log "ERROR" "No se encontró el parser de esquemas: $parser_script"
    return 1
  fi

  if [[ -n "$SCHEMA_FILE" ]]; then
    log "INFO" "Parseando desde archivo: $SCHEMA_FILE"
    if PARSED_FIELDS=$(node "$parser_script" "$SCHEMA_FILE"); then
      log "SUCCESS" "Campos parseados desde archivo exitosamente"
    else
      log "ERROR" "Error parseando campos desde archivo"
      return 1
    fi
  elif [[ -n "$SCHEMA_CONTENT" ]]; then
    log "INFO" "Parseando desde contenido en memoria"
    if PARSED_FIELDS=$(echo "$SCHEMA_CONTENT" | node "$parser_script"); then
      log "SUCCESS" "Campos parseados desde contenido exitosamente"
    else
      log "ERROR" "Error parseando campos desde contenido"
      return 1
    fi
  else
    log "ERROR" "No se puede generar campos: sin esquema disponible"
    return 1
  fi

  log "DEBUG" "Campos parseados guardados en variable PARSED_FIELDS"
}

# ========================
# EXPORT FUNCTIONS
# ========================

# Exportar variables para otros scripts
export_schema_variables() {
  log "INFO" "Exportando variables de esquema para otros scripts"

  export entity EntityPascal SCHEMA_FILE SCHEMA_CONTENT PARSED_FIELDS

  log "DEBUG" "Variables exportadas:"
  log "DEBUG" "  - entity: $entity"
  log "DEBUG" "  - EntityPascal: $EntityPascal"
  log "DEBUG" "  - SCHEMA_FILE: ${SCHEMA_FILE:-'(vacío)'}"
  log "DEBUG" "  - has_json: ${has_json:-'false'}"
}

# ========================
# MAIN FUNCTION
# ========================
main() {
  log "INFO" "Iniciando carga de esquema de entidad"

  # Determinar modo de carga según USE_JSON
  if [[ "$USE_JSON" == true ]]; then
    log "INFO" "Modo JSON activado, cargando desde archivo"
    if load_schema_from_json; then
      export has_json=true
      log "SUCCESS" "Esquema JSON cargado exitosamente"
    else
      log "ERROR" "Error cargando esquema JSON"
      return 1
    fi
  else
    log "INFO" "Modo por defecto activado, creando esquema estándar"
    if create_default_schema; then
      export has_json=false
      log "SUCCESS" "Esquema por defecto creado exitosamente"
    else
      log "ERROR" "Error creando esquema por defecto"
      return 1
    fi
  fi

  # Validar y procesar
  validate_entity_name || return 1
  parse_schema_fields || return 1
  export_schema_variables

  log "SUCCESS" "Carga de esquema completada - Entidad: $entity ($EntityPascal)"
}

# ========================
# EXECUTION LOGIC
# ========================
# Si se llama directamente con bash
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
  main "$@"
fi

# Si se hace source y hay condiciones específicas
if [[ "${BASH_SOURCE[0]}" != "${0}" && (-n "${CREATE_QUERY_UTILS:-}" || $# -gt 0) ]]; then
  main "$@"
fi
