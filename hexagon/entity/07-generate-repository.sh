#!/bin/bash
# shellcheck disable=SC2154
# Generador de repositorios InMemory y Database para una entidad

infra_dir="src/infrastructure"
in_memory_file="$infra_dir/$entity/in-memory-${entity}-repository.js"
database_file="$infra_dir/$entity/database-${entity}-repository.js"

created_files=()

write_file_with_confirm() {
  local filepath=$1
  local content=$2

  if [[ -f "$filepath" && "$AUTO_CONFIRM" != true ]]; then
    read -r -p "⚠️  El archivo $filepath ya existe. ¿Deseas sobrescribirlo? [y/n]: " confirm
    if [[ ! "$confirm" =~ ^[Yy]$ ]]; then
      echo "⏭️  Archivo omitido: $filepath"
      return 1
    fi
  fi

  echo "$content" >"$filepath"
  created_files+=("$filepath")
}

mkdir -p "$infra_dir/$entity"

write_file_with_confirm "$in_memory_file" "$(
  cat <<EOF
import { $EntityPascal } from '../../domain/$entity/$entity.js';
import { mock${EntityPascal} } from '../../domain/$entity/mocks.js';
import {
  applyFilters,
  applySearch,
  applySort,
  applyPagination
} from '../../utils/query-utils.js';

export class InMemory${EntityPascal}Repository {
  constructor() {
    /** @type {${EntityPascal}[]} */
    this.items = [];
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

  /**
   * Buscar todos con opciones de filtros, búsqueda, paginación y orden
   * @param {Object} [options]
   * @param {Object} [options.filters]
   * @param {Object} [options.search]
   * @param {Object} [options.pagination]
   * @param {Object} [options.sort]
   */
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
    const length = this.items.length;
    this.items = this.items.filter(i => i.id !== id);
    return this.items.length < length;
  }

  async deactivateById(id) {
    const item = await this.findById(id);
    if (!item) return null;
    item.deactivate();
    await this.save(item);
    return item;
  }
}
EOF
)"

write_file_with_confirm "$database_file" "$(
  cat <<EOF
// Archivo base para implementar acceso a base de datos para ${EntityPascal}

export class Database${EntityPascal}Repository {
  constructor() {
    // TODO: inicializar conexión o cliente de base de datos
  }

  async save(item) {
    // TODO: implementar guardado en base de datos
    throw new Error('Método save() no implementado');
  }

  async findById(id) {
    // TODO: implementar búsqueda por ID en base de datos
    throw new Error('Método findById() no implementado');
  }

  async findAll(options = {}) {
    // TODO: implementar búsqueda con filtros, búsqueda, paginación y orden
    throw new Error('Método findAll() no implementado');
  }

  async update(id, data) {
    // TODO: implementar actualización en base de datos
    throw new Error('Método update() no implementado');
  }

  async deleteById(id) {
    // TODO: implementar borrado en base de datos
    throw new Error('Método deleteById() no implementado');
  }

  async deactivateById(id) {
    // TODO: implementar desactivación en base de datos
    throw new Error('Método deactivateById() no implementado');
  }
}
EOF
)"

if [ ${#created_files[@]} -gt 0 ]; then
  echo "✅ Repositorios generados:"
  for f in "${created_files[@]}"; do
    echo "   - $f"
  done
else
  echo "⚠️ No se creó ningún archivo."
fi
