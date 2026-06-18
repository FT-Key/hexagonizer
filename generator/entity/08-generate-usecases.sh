#!/bin/bash
# generator/entity/08-generate-usecases.sh
# shellcheck disable=SC2154
set -euo pipefail

source "$PROJECT_ROOT/generator/common/logging.sh"
source "$PROJECT_ROOT/generator/common/io.sh"

# ==========================================
# CONFIGURACIÓN Y CONSTANTES
# ==========================================
if [[ -z "${SCRIPT_DIR:-}" ]]; then
  readonly SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
fi

readonly USE_CASES_BASE_PATH="src/application"
readonly DOMAIN_BASE_PATH="src/domain"

# ==========================================
# GENERADORES DE CÓDIGO
# ==========================================

# Función para generar imports comunes
generate_imports() {
  local entity="$1"
  local entity_pascal="$2"
  local action="$3"

  case "$action" in
  "create" | "update")
    echo "import { ${entity_pascal}Factory } from '../../../domain/$entity/${entity}-factory.js';"
    ;;
  esac
  echo ""
}

# Función para generar constructor común
generate_constructor() {
  echo "  constructor(repository) {"
  echo "    this.repository = repository;"
  echo "  }"
  echo ""
}

# Generadores específicos por tipo de caso de uso
generate_create_use_case() {
  local entity_pascal="$1"

  cat <<EOF
export class Create${entity_pascal} {
$(generate_constructor)
  async execute(data) {
    const entity = ${entity_pascal}Factory.create(data);
    return this.repository.save(entity);
  }
}
EOF
}

generate_update_use_case() {
  local entity="$1"
  local entity_pascal="$2"
  local has_json="${3:-false}"

  cat <<EOF
export class Update${entity_pascal} {
$(generate_constructor)
  async execute(id, data) {
    if (!id) throw new Error('${entity_pascal} id is required');
    
    const existing = await this.repository.findById(id);
    if (!existing) throw new Error('${entity_pascal} not found');
    
EOF

  if [[ "$has_json" == "true" ]]; then
    cat <<EOF
    const updated = ${entity_pascal}Factory.create({
      ...existing,
      ...data,
      id: existing.id,
    });
    return this.repository.save(updated);
EOF
  else
    cat <<EOF
    const updated = { ...existing, ...data };
    return this.repository.save(updated);
EOF
  fi

  echo "  }"
  echo "}"
}

generate_get_use_case() {
  local entity_pascal="$1"

  cat <<EOF
export class Get${entity_pascal} {
$(generate_constructor)
  async execute(id) {
    if (!id) throw new Error('${entity_pascal} id is required');
    return this.repository.findById(id);
  }
}
EOF
}

generate_delete_use_case() {
  local entity_pascal="$1"

  cat <<EOF
export class Delete${entity_pascal} {
$(generate_constructor)
  async execute(id) {
    if (!id) throw new Error('${entity_pascal} id is required');
    return this.repository.deleteById(id);
  }
}
EOF
}

generate_deactivate_use_case() {
  local entity_pascal="$1"

  cat <<EOF
export class Deactivate${entity_pascal} {
$(generate_constructor)
  async execute(id) {
    if (!id) throw new Error('${entity_pascal} id is required');
    return this.repository.deactivateById(id);
  }
}
EOF
}

generate_list_use_case() {
  local entity_pascal="$1"
  local plural_pascal
  plural_pascal="$(pluralize "$entity_pascal")"

  cat <<EOF
export class List${plural_pascal} {
$(generate_constructor)
  /**
   * @param {Object} options
   * @param {Object} options.filters - Filtros a aplicar
   * @param {string} options.search - Término de búsqueda
   * @param {Object} options.pagination - Configuración de paginación
   * @param {number} options.pagination.page - Página actual
   * @param {number} options.pagination.limit - Elementos por página
   * @param {Object} options.sort - Configuración de ordenamiento
   * @param {string} options.sort.field - Campo por el que ordenar
   * @param {string} options.sort.direction - Dirección del ordenamiento (asc|desc)
   * @returns {Promise<{ data: ${entity_pascal}[], meta: Object }>}
   */
  async execute({ filters = {}, search = '', pagination = {}, sort = {} } = {}) {
    const data = await this.repository.findAll({ filters, search, pagination, sort });
    const total = await this.repository.count(filters);
    const { page = 1, limit = 10 } = pagination;
    const pages = Math.ceil(total / limit || 1);

    return {
      data,
      meta: {
        total,
        page,
        limit,
        pages,
        hasNext: page < pages,
        hasPrev: page > 1
      }
    };
  }
}
EOF
}

# ==========================================
# FUNCIÓN PRINCIPAL DE GENERACIÓN
# ==========================================

# Mapa de generadores de casos de uso
declare -A USE_CASE_GENERATORS=(
  ["create"]="generate_create_use_case"
  ["update"]="generate_update_use_case"
  ["get"]="generate_get_use_case"
  ["delete"]="generate_delete_use_case"
  ["deactivate"]="generate_deactivate_use_case"
  ["list"]="generate_list_use_case"
)

# Función principal para generar un caso de uso
generate_use_case() {
  local action="$1"
  local entity="$2"
  local entity_pascal="$3"
  local has_json="${4:-false}"

  local file_path="${USE_CASES_BASE_PATH}/$entity/use-cases/${action}-${entity}.js"

  # Validar que el generador existe
  if [[ -z "${USE_CASE_GENERATORS[$action]:-}" ]]; then
    log "ERROR" "Unsupported action: $action"
    return 1
  fi

  # Crear directorio
  if ! ensure_directory "$(dirname "$file_path")"; then
    return 1
  fi

  # Confirmar sobrescritura si es necesario
  if ! confirm_overwrite "$file_path"; then
    return 0
  fi

  # Generar el contenido
  local content
  local generator_func="${USE_CASE_GENERATORS[$action]}"

  case "$action" in
  "create")
    content="$(generate_imports "$entity" "$entity_pascal" "$action")$($generator_func "$entity_pascal")"
    ;;
  "update")
    content="$(generate_imports "$entity" "$entity_pascal" "$action")$($generator_func "$entity" "$entity_pascal" "$has_json")"
    ;;
  *)
    content="$($generator_func "$entity_pascal")"
    ;;
  esac

  # Escribir el archivo
  if printf "%s\n" "$content" >"$file_path"; then
    log "SUCCESS" "Generated: $file_path"
  else
    log "ERROR" "Could not write file: $file_path"
    return 1
  fi
}

# ==========================================
# FUNCIÓN PRINCIPAL
# ==========================================

generate_all_use_cases() {
  local entity="$1"
  local entity_pascal="$2"
  local has_json="${3:-false}"
  local actions=("${@:4}")

  # Si no se especifican acciones, usar las predeterminadas
  if [[ ${#actions[@]} -eq 0 ]]; then
    actions=("create" "get" "update" "delete" "deactivate" "list")
  fi

  local generated_count=0
  local failed_count=0

  log "INFO" "Starting use case generation for entity: $entity"
  log "INFO" "Actions to generate: ${actions[*]}"

  for action in "${actions[@]}"; do
    if generate_use_case "$action" "$entity" "$entity_pascal" "$has_json"; then
      ((generated_count++))
    else
      ((failed_count++))
    fi
  done

  # Resumen final
  echo ""
  if [[ $failed_count -eq 0 ]]; then
    log "SUCCESS" "All use cases generated successfully ($generated_count/$((generated_count + failed_count)))"
  else
    log "WARN" "Generation completed with some errors ($generated_count successful, $failed_count failed)"
  fi
}

# =============================================================================
# EJECUCIÓN PRINCIPAL
# =============================================================================

main() {
  # Verificar que las variables necesarias estén definidas
  if [[ -z "${entity:-}" ]] || [[ -z "${EntityPascal:-}" ]]; then
    log "ERROR" "Variables 'entity' and 'EntityPascal' must be defined before running"
    log "INFO" "Required variables:"
    log "INFO" "  - entity: lowercase entity name (e.g. 'user')"
    log "INFO" "  - EntityPascal: entity name in PascalCase (e.g. 'User')"
    log "INFO" "Optional variables:"
    log "INFO" "  - has_json: usar factory con JSON (default: false)"
    log "INFO" "  - AUTO_CONFIRM: auto-confirm overwrites (default: false)"
    return 1
  fi

  # Validar entidad
  if ! validate_entity "$entity"; then
    return 1
  fi

  log "INFO" "=== USE CASE GENERATOR ==="
  log "INFO" "Entity: $entity ($EntityPascal)"
  log "INFO" "JSON Factory config: ${has_json:-false}"
  log "INFO" "Auto-confirm: ${AUTO_CONFIRM:-false}"
  echo ""

  # Ejecutar generación
  local success=true
  if ! generate_all_use_cases "$entity" "$EntityPascal" "${has_json:-false}"; then
    success=false
  fi

  # Mostrar resumen final
  show_use_cases_summary "$success"

  return $([[ "$success" == true ]] && echo 0 || echo 1)
}

# Función para mostrar resumen de la generación
show_use_cases_summary() {
  local success="$1"

  echo ""
  log "INFO" "=== USE CASE GENERATION SUMMARY ==="

  if [[ "$success" == true ]]; then
    log "SUCCESS" "✅ Use cases generated successfully"
    log "INFO" "Location: ${USE_CASES_BASE_PATH}/$entity/use-cases/"

    # Show generated files
    if [[ -d "${USE_CASES_BASE_PATH}/$entity/use-cases" ]]; then
      log "INFO" "Generated files:"
      find "${USE_CASES_BASE_PATH}/$entity/use-cases" -name "*.js" -type f | while read -r file; do
        log "INFO" "  📄 $(basename "$file")"
      done
    fi
  else
    log "ERROR" "❌ Use case generation failed"
    log "INFO" "Check previous error messages for details"
  fi

  echo ""
}

# Ejecutar solo si el script es llamado directamente
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
  main "$@"
fi

# Llamada implícita si fue sourced desde otro script
if [[ -n "${entity:-}" && -n "${EntityPascal:-}" ]]; then
  main "$@"
fi
