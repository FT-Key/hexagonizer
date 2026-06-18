#!/bin/bash
# generator/entity/06-generate-repository-mocks.sh
# Generador de repositorios InMemory y Database para una entidad
# shellcheck disable=SC2154

set -euo pipefail

source "$PROJECT_ROOT/generator/common/logging.sh"
source "$PROJECT_ROOT/generator/common/io.sh"

# =============================================================================
# CONFIGURACIÓN
# =============================================================================
readonly SCRIPT_NAME="$(basename "$0")"
readonly INFRA_DIR="src/infrastructure"
created_files=()

# =============================================================================
# VALIDACIONES
# =============================================================================
validate_entity() {
  if [[ -z "${entity:-}" ]]; then
    log "ERROR" "La variable 'entity' no está definida"
    exit 1
  fi

  if [[ -z "${EntityPascal:-}" ]]; then
    log "ERROR" "La variable 'EntityPascal' no está definida"
    exit 1
  fi
}

# =============================================================================
# ARCHIVOS Y DIRECTORIOS
# =============================================================================
create_directory_structure() {
  local entity_dir="$INFRA_DIR/$entity"

  if ! ensure_directory "$entity_dir"; then
    exit 1
  fi

  log "INFO" "📁 Directorio creado: $entity_dir"
}

# =============================================================================
# GENERADORES DE CONTENIDO
# =============================================================================

generate_in_memory_repository() {
  cat <<EOF
import { ${EntityPascal} } from '../../domain/${entity}/${entity}.js';
import { mock${EntityPascal}List } from '../../domain/${entity}/mocks.js';
import {
  applyFilters,
  applySearch,
  applySort,
  applyPagination
} from '../../utils/query-utils.js';

/**
 * Repositorio en memoria para ${EntityPascal}
 * Implementa todas las operaciones CRUD básicas
 */
export class InMemory${EntityPascal}Repository {
  constructor() {
    /** @type {${EntityPascal}[]} */
    this.items = [...mock${EntityPascal}List];
  }

  async save(item) {
    const index = this.items.findIndex(i => i.id === item.id);
    
    if (index === -1) {
      this.items.push(item);
    } else {
      this.items[index] = item;
    }
    
    return item;
  }

  async findById(id) {
    return this.items.find(i => i.id === id) || null;
  }

  async findAll(options = {}) {
    let result = [...this.items];

    result = applyFilters(result, options.filters);
    result = applySearch(result, options.search);
    result = applySort(result, options.sort);
    result = applyPagination(result, options.pagination);

    return result;
  }

  async update(id, data) {
    const item = await this.findById(id);
    if (!item) return null;
    
    item.update(data);
    await this.save(item);
    return item;
  }

  async deleteById(id) {
    const initialLength = this.items.length;
    this.items = this.items.filter(i => i.id !== id);
    return this.items.length < initialLength;
  }

  async deactivateById(id) {
    const item = await this.findById(id);
    if (!item) return null;
    
    item.deactivate();
    await this.save(item);
    return item;
  }

  async count() {
    return this.items.length;
  }

  async clear() {
    this.items = [];
  }
}
EOF
}

generate_database_repository() {
  cat <<EOF
/**
 * Repositorio de base de datos para ${EntityPascal}
 * Archivo base para implementar acceso a base de datos
 */
export class Database${EntityPascal}Repository {
  constructor(dbConnection) {
    this.db = dbConnection;
    this.tableName = '${entity}s'; // Ajustar según convención de nombres
  }

  async save(item) {
    throw new Error('Método save() no implementado en Database${EntityPascal}Repository');
  }

  async findById(id) {
    throw new Error('Método findById() no implementado en Database${EntityPascal}Repository');
  }

  async findAll(options = {}) {
    throw new Error('Método findAll() no implementado en Database${EntityPascal}Repository');
  }

  async update(id, data) {
    throw new Error('Método update() no implementado en Database${EntityPascal}Repository');
  }

  async deleteById(id) {
    throw new Error('Método deleteById() no implementado en Database${EntityPascal}Repository');
  }

  async deactivateById(id) {
    throw new Error('Método deactivateById() no implementado en Database${EntityPascal}Repository');
  }

  async count(filters = {}) {
    throw new Error('Método count() no implementado en Database${EntityPascal}Repository');
  }

  mapRow${EntityPascal}(row) {
    throw new Error('Método mapRow${EntityPascal}() no implementado');
  }
}
EOF
}

# =============================================================================
# FUNCIÓN PRINCIPAL DE GENERACIÓN
# =============================================================================
generate_repositories() {
  log "INFO" "Iniciando generación de repositorios para la entidad: $entity"

  validate_entity
  create_directory_structure

  local in_memory_file="$INFRA_DIR/$entity/in-memory-${entity}-repository.js"
  local database_file="$INFRA_DIR/$entity/database-${entity}-repository.js"

  log "INFO" "Generando repositorio en memoria..."
  if write_file "$(generate_in_memory_repository)" "$in_memory_file"; then
    created_files+=("$in_memory_file")
  fi

  log "INFO" "Generando repositorio de base de datos..."
  if write_file "$(generate_database_repository)" "$database_file"; then
    created_files+=("$database_file")
  fi
}

# =============================================================================
# RESUMEN FINAL
# =============================================================================
show_summary() {
  echo ""
  log "INFO" "Resumen de generación de repositorios"

  if [[ ${#created_files[@]} -gt 0 ]]; then
    log "SUCCESS" "Archivos creados:"
    printf '   %s\n' "${created_files[@]}"
  else
    log "WARN" "No se creó ningún archivo nuevo."
  fi
}

# =============================================================================
# EJECUCIÓN
# =============================================================================
main() {
  generate_repositories
  show_summary
}

if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
  main "$@"
fi

if [[ -n "${entity:-}" && -n "${EntityPascal:-}" ]]; then
  main "$@"
fi
