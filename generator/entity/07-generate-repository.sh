#!/bin/bash
# generator/entity/06-generate-repository-mocks.sh
# shellcheck disable=SC2154
# Generador de repositorios InMemory y Database para una entidad

set -euo pipefail

# =============================================================================
# CONFIGURACIÓN
# =============================================================================

readonly SCRIPT_NAME="$(basename "$0")"
readonly INFRA_DIR="src/infrastructure"
created_files=()

# =============================================================================
# FUNCIONES DE UTILIDAD
# =============================================================================

log_info() {
  echo "ℹ️  $*"
}

log_success() {
  echo "✅ $*"
}

log_warning() {
  echo "⚠️  $*"
}

log_error() {
  echo "❌ $*" >&2
}

validate_entity() {
  if [[ -z "${entity:-}" ]]; then
    log_error "Variable 'entity' no está definida"
    exit 1
  fi

  if [[ -z "${EntityPascal:-}" ]]; then
    log_error "Variable 'EntityPascal' no está definida"
    exit 1
  fi
}

# =============================================================================
# FUNCIONES DE ARCHIVOS
# =============================================================================

write_file_with_confirm() {
  local filepath="$1"
  local content="$2"

  if [[ -f "$filepath" && "${AUTO_CONFIRM:-false}" != "true" ]]; then
    read -r -p "⚠️  El archivo $filepath ya existe. ¿Deseas sobrescribirlo? [y/n]: " confirm
    if [[ ! "$confirm" =~ ^[Yy]$ ]]; then
      log_info "Archivo omitido: $filepath"
      return 1
    fi
  fi

  echo "$content" >"$filepath"
  created_files+=("$filepath")
  return 0
}

create_directory_structure() {
  local entity_dir="$INFRA_DIR/$entity"

  if ! mkdir -p "$entity_dir"; then
    log_error "No se pudo crear el directorio: $entity_dir"
    exit 1
  fi

  log_info "Directorio creado: $entity_dir"
}

# =============================================================================
# GENERADORES DE CONTENIDO
# =============================================================================

generate_in_memory_repository() {
  cat <<EOF
import { ${EntityPascal} } from '../../domain/${entity}/${entity}.js';
import { mock${EntityPascal} } from '../../domain/${entity}/mocks.js';
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
    this.items = [];
  }

  /**
   * Guarda o actualiza un elemento
   * @param {${EntityPascal}} item - El elemento a guardar
   * @returns {Promise<${EntityPascal}>} El elemento guardado
   */
  async save(item) {
    const index = this.items.findIndex(i => i.id === item.id);
    
    if (index === -1) {
      this.items.push(item);
    } else {
      this.items[index] = item;
    }
    
    return item;
  }

  /**
   * Busca un elemento por su ID
   * @param {string} id - ID del elemento
   * @returns {Promise<${EntityPascal}|null>} El elemento encontrado o null
   */
  async findById(id) {
    return this.items.find(i => i.id === id) || null;
  }

  /**
   * Busca todos los elementos con opciones de filtros, búsqueda, paginación y orden
   * @param {Object} [options] - Opciones de búsqueda
   * @param {Object} [options.filters] - Filtros a aplicar
   * @param {Object} [options.search] - Parámetros de búsqueda
   * @param {Object} [options.pagination] - Configuración de paginación
   * @param {Object} [options.sort] - Configuración de ordenamiento
   * @returns {Promise<${EntityPascal}[]>} Lista de elementos
   */
  async findAll(options = {}) {
    let result = [...this.items];

    result = applyFilters(result, options.filters);
    result = applySearch(result, options.search);
    result = applySort(result, options.sort);
    result = applyPagination(result, options.pagination);

    return result;
  }

  /**
   * Actualiza un elemento por su ID
   * @param {string} id - ID del elemento
   * @param {Object} data - Datos a actualizar
   * @returns {Promise<${EntityPascal}|null>} El elemento actualizado o null
   */
  async update(id, data) {
    const item = await this.findById(id);
    if (!item) return null;
    
    item.update(data);
    await this.save(item);
    return item;
  }

  /**
   * Elimina un elemento por su ID
   * @param {string} id - ID del elemento
   * @returns {Promise<boolean>} true si se eliminó, false si no existía
   */
  async deleteById(id) {
    const initialLength = this.items.length;
    this.items = this.items.filter(i => i.id !== id);
    return this.items.length < initialLength;
  }

  /**
   * Desactiva un elemento por su ID
   * @param {string} id - ID del elemento
   * @returns {Promise<${EntityPascal}|null>} El elemento desactivado o null
   */
  async deactivateById(id) {
    const item = await this.findById(id);
    if (!item) return null;
    
    item.deactivate();
    await this.save(item);
    return item;
  }

  /**
   * Obtiene el número total de elementos
   * @returns {Promise<number>} Número total de elementos
   */
  async count() {
    return this.items.length;
  }

  /**
   * Limpia todos los elementos del repositorio
   * @returns {Promise<void>}
   */
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

  /**
   * Guarda o actualiza un elemento en la base de datos
   * @param {${EntityPascal}} item - El elemento a guardar
   * @returns {Promise<${EntityPascal}>} El elemento guardado
   * @throws {Error} Si no está implementado
   */
  async save(item) {
    // TODO: implementar guardado en base de datos
    // Ejemplo con SQL:
    // const query = 'INSERT INTO \${this.tableName} (...) VALUES (...) ON DUPLICATE KEY UPDATE ...';
    // const result = await this.db.query(query, [...]);
    // return result;
    
    throw new Error('Método save() no implementado en Database${EntityPascal}Repository');
  }

  /**
   * Busca un elemento por su ID en la base de datos
   * @param {string} id - ID del elemento
   * @returns {Promise<${EntityPascal}|null>} El elemento encontrado o null
   * @throws {Error} Si no está implementado
   */
  async findById(id) {
    // TODO: implementar búsqueda por ID en base de datos
    // Ejemplo con SQL:
    // const query = 'SELECT * FROM \${this.tableName} WHERE id = ?';
    // const [rows] = await this.db.query(query, [id]);
    // return rows.length > 0 ? this.mapRow${EntityPascal}(rows[0]) : null;
    
    throw new Error('Método findById() no implementado en Database${EntityPascal}Repository');
  }

  /**
   * Busca todos los elementos con opciones avanzadas
   * @param {Object} [options] - Opciones de búsqueda
   * @param {Object} [options.filters] - Filtros a aplicar
   * @param {Object} [options.search] - Parámetros de búsqueda
   * @param {Object} [options.pagination] - Configuración de paginación
   * @param {Object} [options.sort] - Configuración de ordenamiento
   * @returns {Promise<${EntityPascal}[]>} Lista de elementos
   * @throws {Error} Si no está implementado
   */
  async findAll(options = {}) {
    // TODO: implementar búsqueda con filtros, búsqueda, paginación y orden
    // Construir query SQL dinámicamente basado en las opciones
    
    throw new Error('Método findAll() no implementado en Database${EntityPascal}Repository');
  }

  /**
   * Actualiza un elemento en la base de datos
   * @param {string} id - ID del elemento
   * @param {Object} data - Datos a actualizar
   * @returns {Promise<${EntityPascal}|null>} El elemento actualizado o null
   * @throws {Error} Si no está implementado
   */
  async update(id, data) {
    // TODO: implementar actualización en base de datos
    // const query = 'UPDATE \${this.tableName} SET ... WHERE id = ?';
    // await this.db.query(query, [..., id]);
    // return this.findById(id);
    
    throw new Error('Método update() no implementado en Database${EntityPascal}Repository');
  }

  /**
   * Elimina un elemento de la base de datos
   * @param {string} id - ID del elemento
   * @returns {Promise<boolean>} true si se eliminó, false si no existía
   * @throws {Error} Si no está implementado
   */
  async deleteById(id) {
    // TODO: implementar borrado en base de datos
    // const query = 'DELETE FROM \${this.tableName} WHERE id = ?';
    // const result = await this.db.query(query, [id]);
    // return result.affectedRows > 0;
    
    throw new Error('Método deleteById() no implementado en Database${EntityPascal}Repository');
  }

  /**
   * Desactiva un elemento en la base de datos
   * @param {string} id - ID del elemento
   * @returns {Promise<${EntityPascal}|null>} El elemento desactivado o null
   * @throws {Error} Si no está implementado
   */
  async deactivateById(id) {
    // TODO: implementar desactivación en base de datos
    // const query = 'UPDATE \${this.tableName} SET active = false WHERE id = ?';
    // await this.db.query(query, [id]);
    // return this.findById(id);
    
    throw new Error('Método deactivateById() no implementado en Database${EntityPascal}Repository');
  }

  /**
   * Cuenta el número total de elementos
   * @param {Object} [filters] - Filtros opcionales
   * @returns {Promise<number>} Número total de elementos
   * @throws {Error} Si no está implementado
   */
  async count(filters = {}) {
    // TODO: implementar conteo con filtros opcionales
    throw new Error('Método count() no implementado en Database${EntityPascal}Repository');
  }

  /**
   * Mapea una fila de base de datos a un objeto ${EntityPascal}
   * @private
   * @param {Object} row - Fila de la base de datos
   * @returns {${EntityPascal}} Instancia de ${EntityPascal}
   */
  mapRow${EntityPascal}(row) {
    // TODO: implementar mapeo de datos de BD a objeto de dominio
    // return new ${EntityPascal}({
    //   id: row.id,
    //   ...row
    // });
    throw new Error('Método mapRow${EntityPascal}() no implementado');
  }
}
EOF
}

# =============================================================================
# FUNCIÓN PRINCIPAL
# =============================================================================

generate_repositories() {
  log_info "Iniciando generación de repositorios para entidad: $entity"

  # Validar variables requeridas
  validate_entity

  # Crear estructura de directorios
  create_directory_structure

  # Definir rutas de archivos
  local in_memory_file="$INFRA_DIR/$entity/in-memory-${entity}-repository.js"
  local database_file="$INFRA_DIR/$entity/database-${entity}-repository.js"

  # Generar repositorio en memoria
  log_info "Generando repositorio en memoria..."
  if write_file_with_confirm "$in_memory_file" "$(generate_in_memory_repository)"; then
    log_success "Repositorio en memoria creado: $in_memory_file"
  fi

  # Generar repositorio de base de datos
  log_info "Generando repositorio de base de datos..."
  if write_file_with_confirm "$database_file" "$(generate_database_repository)"; then
    log_success "Repositorio de base de datos creado: $database_file"
  fi
}

show_summary() {
  if [[ ${#created_files[@]} -gt 0 ]]; then
    log_success "Repositorios generados exitosamente:"
    printf '   - %s\n' "${created_files[@]}"
  else
    log_warning "No se creó ningún archivo."
  fi
}

# =============================================================================
# EJECUCIÓN PRINCIPAL
# =============================================================================

main() {
  generate_repositories
  show_summary
}

# Ejecutar solo si el script es llamado directamente
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
  main "$@"
fi

# Llamada implícita si fue sourced desde otro script
if [[ -n "${entity:-}" && -n "${EntityPascal:-}" ]]; then
  main "$@"
fi
