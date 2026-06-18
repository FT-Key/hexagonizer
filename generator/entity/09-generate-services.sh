#!/bin/bash
# generator/entity/09-generate-services.sh
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

if [[ -z "${SERVICES_BASE_PATH:-}" ]]; then
  readonly SERVICES_BASE_PATH="src/application"
fi

# ==========================================
# GENERADORES DE SERVICIOS
# ==========================================

# Función para generar README del directorio de servicios
generate_services_readme() {
  local entity="$1"
  local entity_pascal="$2"

  cat <<EOF
# Servicios para la entidad ${entity_pascal}

Este directorio contiene servicios de aplicación especializados para la entidad ${entity_pascal}.

## Servicios disponibles

- \`get-active-${entity}.js\`: Obtiene todas las entidades activas
- \`get-inactive-${entity}.js\`: Obtiene todas las entidades inactivas
- \`count-${entity}.js\`: Cuenta entidades con filtros opcionales

## Convenciones

- Los servicios deben ser funciones puras cuando sea posible
- Utilizar nombres descriptivos que indiquen claramente la funcionalidad
- Documentar parámetros y valores de retorno con JSDoc
- Manejar errores de forma consistente

## Ejemplo de uso

\`\`\`javascript
import { getActive${entity_pascal}s } from './get-active-${entity}.js';

const activeEntities = await getActive${entity_pascal}s(repository);
\`\`\`
EOF
}

# Función para generar servicio getActive
generate_get_active_service() {
  local entity="$1"
  local entity_pascal="$2"
  local plural_pascal
  plural_pascal="$(pluralize "$entity_pascal")"

  cat <<EOF
/**
 * Servicio para obtener todas las entidades ${entity} activas
 * @param {Object} repository - Repositorio de la entidad ${entity_pascal}
 * @param {Object} options - Opciones adicionales
 * @param {Object} options.filters - Filtros adicionales a aplicar
 * @returns {Promise<${entity_pascal}[]>} Array de entidades activas
 */
export async function getActive${plural_pascal}(repository, options = {}) {
  const { filters = {} } = options;
  
  // Combinar el filtro de activo con filtros adicionales
  const activeFilters = {
    ...filters,
    active: true
  };
  
  try {
    return await repository.findAll({ 
      filters: activeFilters,
      ...options 
    });
  } catch (error) {
    throw new Error(\`Error al obtener ${entity} activos: \${error.message}\`);
  }
}
EOF
}

# Función para generar servicio getInactive
generate_get_inactive_service() {
  local entity="$1"
  local entity_pascal="$2"
  local plural_pascal
  plural_pascal="$(pluralize "$entity_pascal")"

  cat <<EOF
/**
 * Servicio para obtener todas las entidades ${entity} inactivas
 * @param {Object} repository - Repositorio de la entidad ${entity_pascal}
 * @param {Object} options - Opciones adicionales
 * @param {Object} options.filters - Filtros adicionales a aplicar
 * @returns {Promise<${entity_pascal}[]>} Array de entidades inactivas
 */
export async function getInactive${plural_pascal}(repository, options = {}) {
  const { filters = {} } = options;
  
  // Combinar el filtro de inactivo con filtros adicionales
  const inactiveFilters = {
    ...filters,
    active: false
  };
  
  try {
    return await repository.findAll({ 
      filters: inactiveFilters,
      ...options 
    });
  } catch (error) {
    throw new Error(\`Error al obtener ${entity} inactivos: \${error.message}\`);
  }
}
EOF
}

# Función para generar servicio de conteo
generate_count_service() {
  local entity="$1"
  local entity_pascal="$2"
  local plural_pascal
  plural_pascal="$(pluralize "$entity_pascal")"

  cat <<EOF
/**
 * Servicio para contar entidades ${entity} con filtros opcionales
 * @param {Object} repository - Repositorio de la entidad ${entity_pascal}
 * @param {Object} options - Opciones de filtrado
 * @param {Object} options.filters - Filtros a aplicar
 * @param {boolean} options.activeOnly - Solo contar entidades activas
 * @returns {Promise<number>} Número de entidades que coinciden con los criterios
 */
export async function count${plural_pascal}(repository, options = {}) {
  const { filters = {}, activeOnly = false } = options;
  
  let finalFilters = { ...filters };
  
  if (activeOnly) {
    finalFilters.active = true;
  }
  
  try {
    // Si el repositorio tiene método count, usarlo
    if (typeof repository.count === 'function') {
      return await repository.count({ filters: finalFilters });
    }
    
    // Fallback: obtener todos y contar
    const entities = await repository.findAll({ filters: finalFilters });
    return entities.length;
  } catch (error) {
    throw new Error(\`Error al contar ${entity}: \${error.message}\`);
  }
}

/**
 * Servicio para obtener estadísticas básicas de la entidad
 * @param {Object} repository - Repositorio de la entidad ${entity_pascal}
 * @returns {Promise<Object>} Estadísticas de la entidad
 */
export async function get${entity_pascal}Stats(repository) {
  try {
    const [total, active, inactive] = await Promise.all([
      count${plural_pascal}(repository),
      count${plural_pascal}(repository, { activeOnly: true }),
      count${plural_pascal}(repository, { filters: { active: false } })
    ]);
    
    return {
      total,
      active,
      inactive,
      activePercentage: total > 0 ? Math.round((active / total) * 100) : 0
    };
  } catch (error) {
    throw new Error(\`Error al obtener estadísticas de ${entity}: \${error.message}\`);
  }
}
EOF
}

# ==========================================
# FUNCIÓN PRINCIPAL DE GENERACIÓN
# ==========================================

# Mapa de generadores de servicios
declare -A SERVICE_GENERATORS=(
  ["get-active"]="generate_get_active_service"
  ["get-inactive"]="generate_get_inactive_service"
  ["count"]="generate_count_service"
)

# Función para generar un servicio específico
generate_service() {
  local service_type="$1"
  local entity="$2"
  local entity_pascal="$3"
  local services_path="$4"

  # Validar que el generador existe
  if [[ -z "${SERVICE_GENERATORS[$service_type]:-}" ]]; then
    log "ERROR" "Unsupported service type: $service_type"
    return 1
  fi

  local service_file="$services_path/${service_type}-${entity}.js"

  # Confirmar sobrescritura si es necesario
  if ! confirm_overwrite "$service_file" "service"; then
    return 0
  fi

  # Generar el contenido
  local generator_func="${SERVICE_GENERATORS[$service_type]}"
  local content
  content="$($generator_func "$entity" "$entity_pascal")"

  # Escribir el archivo
  if printf "%s\n" "$content" >"$service_file"; then
    log "SUCCESS" "Generated: $service_file"
    return 0
  else
    log "ERROR" "Could not write file: $service_file"
    return 1
  fi
}

# Función para crear la estructura de servicios
create_services_structure() {
  local entity="$1"
  local entity_pascal="$2"

  local services_path="${SERVICES_BASE_PATH}/$entity/services"
  local readme_file="$services_path/README.md"

  log "INFO" "Creating service structure for: $entity"

  # Crear directorio
  if ! ensure_directory "$services_path"; then
    return 1
  fi

  # Generar README si es necesario
  if confirm_overwrite "$readme_file" "README"; then
    local readme_content
    readme_content="$(generate_services_readme "$entity" "$entity_pascal")"

    if printf "%s\n" "$readme_content" >"$readme_file"; then
      log "SUCCESS" "README generated: $readme_file"
    else
      log "ERROR" "Could not generate README: $readme_file"
      return 1
    fi
  fi

  echo "$services_path"
}

# Función principal para generar todos los servicios
generate_all_services() {
  local entity="$1"
  local entity_pascal="$2"
  local services=("${@:3}")

  # Si no se especifican servicios, usar los predeterminados
  if [[ ${#services[@]} -eq 0 ]]; then
    services=("get-active" "get-inactive" "count")
  fi

  # Crear estructura de servicios
  local services_path
  if ! services_path="$(create_services_structure "$entity" "$entity_pascal" | tail -n 1)"; then
    log "ERROR" "Could not create service structure"
    return 1
  fi

  local generated_count=0
  local failed_count=0

  log "INFO" "Generating services: ${services[*]}"

  # Generar cada servicio
  for service in "${services[@]}"; do
    if generate_service "$service" "$entity" "$entity_pascal" "$services_path"; then
      ((generated_count++))
    else
      ((failed_count++))
    fi
  done

  # Retornar estado basado en resultados
  if [[ $failed_count -eq 0 ]]; then
    return 0
  else
    return 1
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
    log "INFO" "  - AUTO_CONFIRM: auto-confirm overwrites (default: false)"
    return 1
  fi

  # Validar entidad
  if ! validate_entity "$entity"; then
    return 1
  fi

  log "INFO" "=== SERVICE GENERATOR ==="
  log "INFO" "Entity: $entity ($EntityPascal)"
  log "INFO" "Auto-confirm: ${AUTO_CONFIRM:-false}"
  echo ""

  # Ejecutar generación
  local success=true
  if ! generate_all_services "$entity" "$EntityPascal"; then
    success=false
  fi

  # Mostrar resumen final
  show_services_summary "$success"

  return $([[ "$success" == true ]] && echo 0 || echo 1)
}

# Función para mostrar resumen de la generación
show_services_summary() {
  local success="$1"

  echo ""
  log "INFO" "=== SERVICE GENERATION SUMMARY ==="

  if [[ "$success" == true ]]; then
    log "SUCCESS" "✅ Services generated successfully"
    log "INFO" "Location: ${SERVICES_BASE_PATH}/$entity/services/"

    # Show generated files
    if [[ -d "${SERVICES_BASE_PATH}/$entity/services" ]]; then
      log "INFO" "Generated files:"
      find "${SERVICES_BASE_PATH}/$entity/services" -name "*.js" -type f | while read -r file; do
        log "INFO" "  📄 $(basename "$file")"
      done

      # Mostrar README si existe
      if [[ -f "${SERVICES_BASE_PATH}/$entity/services/README.md" ]]; then
        log "INFO" "  📋 README.md"
      fi
    fi
  else
    log "ERROR" "❌ Service generation failed"
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
