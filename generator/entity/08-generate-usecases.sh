#!/bin/bash
# generator/entity/08-generate-usecases.sh
# shellcheck disable=SC2154
set -euo pipefail

# ==========================================
# CONFIGURACIÓN Y CONSTANTES
# ==========================================
# Solo definir SCRIPT_DIR si no existe (para compatibilidad con otros módulos)
if [[ -z "${SCRIPT_DIR:-}" ]]; then
  readonly SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
fi

readonly USE_CASES_BASE_PATH="src/application"
readonly DOMAIN_BASE_PATH="src/domain"

# Colores para output (definir solo si no están definidos)
if [[ -z "${RED:-}" ]]; then
  readonly RED='\033[0;31m'
  readonly GREEN='\033[0;32m'
  readonly YELLOW='\033[1;33m'
  readonly BLUE='\033[0;34m'
  readonly NC='\033[0m' # No Color
fi

# ==========================================
# FUNCIONES DE UTILIDAD
# ==========================================

# Función para logging con colores
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

# Función mejorada para pluralización
pluralize() {
  local word="$1"

  # Casos especiales en español e inglés
  case "$word" in
  *[aeiou]) echo "${word}s" ;;
  *[zs]) echo "${word}es" ;;
  *y) echo "${word%y}ies" ;;
  *) echo "${word}s" ;;
  esac
}

# Función para validar entrada
validate_entity() {
  local entity="$1"

  if [[ -z "$entity" ]]; then
    log "ERROR" "El nombre de la entidad no puede estar vacío"
    return 1
  fi

  if [[ ! "$entity" =~ ^[a-zA-Z][a-zA-Z0-9_-]*$ ]]; then
    log "ERROR" "El nombre de la entidad debe comenzar con una letra y contener solo letras, números, guiones y guiones bajos"
    return 1
  fi

  return 0
}

# Función para confirmar sobrescritura
confirm_overwrite() {
  local file_path="$1"
  local auto_confirm="${AUTO_CONFIRM:-false}"

  if [[ -f "$file_path" && "$auto_confirm" != "true" ]]; then
    printf "${YELLOW}⚠️  El archivo %s ya existe. ¿Deseas sobrescribirlo? [s/N]: ${NC}" "$file_path"
    read -r confirm
    if [[ ! "$confirm" =~ ^[Ss]$ ]]; then
      log "INFO" "Omitido: $file_path"
      return 1
    fi
  fi
  return 0
}

# Función para crear directorio de forma segura
ensure_directory() {
  local dir_path="$1"

  if ! mkdir -p "$dir_path" 2>/dev/null; then
    log "ERROR" "No se pudo crear el directorio: $dir_path"
    return 1
  fi
}

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
    log "ERROR" "Acción no soportada: $action"
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
    log "SUCCESS" "Generado: $file_path"
  else
    log "ERROR" "No se pudo escribir el archivo: $file_path"
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

  log "INFO" "Iniciando generación de casos de uso para la entidad: $entity"
  log "INFO" "Acciones a generar: ${actions[*]}"

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
    log "SUCCESS" "Todos los casos de uso generados exitosamente ($generated_count/$((generated_count + failed_count)))"
  else
    log "WARN" "Generación completada con algunos errores ($generated_count exitosos, $failed_count fallidos)"
  fi
}

# =============================================================================
# EJECUCIÓN PRINCIPAL
# =============================================================================

main() {
  # Verificar que las variables necesarias estén definidas
  if [[ -z "${entity:-}" ]] || [[ -z "${EntityPascal:-}" ]]; then
    log "ERROR" "Las variables 'entity' y 'EntityPascal' deben estar definidas antes de ejecutar"
    log "INFO" "Variables requeridas:"
    log "INFO" "  - entity: nombre de la entidad en minúsculas (ej: 'user')"
    log "INFO" "  - EntityPascal: nombre de la entidad en PascalCase (ej: 'User')"
    log "INFO" "Variables opcionales:"
    log "INFO" "  - has_json: usar factory con JSON (default: false)"
    log "INFO" "  - AUTO_CONFIRM: confirmar automáticamente sobrescrituras (default: false)"
    return 1
  fi

  # Validar entidad
  if ! validate_entity "$entity"; then
    return 1
  fi

  log "INFO" "=== GENERADOR DE CASOS DE USO ==="
  log "INFO" "Entidad: $entity ($EntityPascal)"
  log "INFO" "Configuración JSON Factory: ${has_json:-false}"
  log "INFO" "Auto-confirmación: ${AUTO_CONFIRM:-false}"
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
  log "INFO" "=== RESUMEN DE GENERACIÓN DE CASOS DE USO ==="

  if [[ "$success" == true ]]; then
    log "SUCCESS" "✅ Casos de uso generados exitosamente"
    log "INFO" "Ubicación: ${USE_CASES_BASE_PATH}/$entity/use-cases/"

    # Mostrar archivos generados
    if [[ -d "${USE_CASES_BASE_PATH}/$entity/use-cases" ]]; then
      log "INFO" "Archivos generados:"
      find "${USE_CASES_BASE_PATH}/$entity/use-cases" -name "*.js" -type f | while read -r file; do
        log "INFO" "  📄 $(basename "$file")"
      done
    fi
  else
    log "ERROR" "❌ La generación de casos de uso falló"
    log "INFO" "Revisa los mensajes de error anteriores para más detalles"
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
