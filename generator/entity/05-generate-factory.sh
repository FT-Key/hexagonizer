#!/bin/bash
# generator/entity/05-generate-factory.sh
# shellcheck disable=SC2154
set -e

factory_file="src/domain/$entity/${entity}-factory.js"

confirm_file_overwrite() {
  if [[ -f "$factory_file" && "$AUTO_CONFIRM" != true ]]; then
    read -r -p "⚠️  El archivo $factory_file ya existe. ¿Desea sobrescribirlo? [y/n]: " confirm
    [[ ! "$confirm" =~ ^[Yy]$ ]] && {
      echo "⏭️  Se omitió la generación de $factory_file"
      exit 0
    }
  fi
}

write_factory_file() {
  cat >"$factory_file" <<EOF
import { $EntityPascal } from './$entity.js';
import { validate${EntityPascal} } from './validate-$entity.js';

export class ${EntityPascal}Factory {
  /**
   * Crea una instancia de $EntityPascal validando los datos.
   * @param {Object} data - Datos para crear la instancia
   * @returns {$EntityPascal} Nueva instancia validada
   * @throws {Error} Si los datos no son válidos
   */
  static create(data) {
    validate${EntityPascal}(data);
    return new $EntityPascal(data);
  }

  /**
   * Crea múltiples instancias de $EntityPascal.
   * @param {Array<Object>} dataArray - Array de datos para crear instancias
   * @returns {Array<$EntityPascal>} Array de instancias validadas
   * @throws {Error} Si algún dato no es válido
   */
  static createMany(dataArray) {
    if (!Array.isArray(dataArray)) {
      throw new Error('dataArray must be an array');
    }
    return dataArray.map(data => this.create(data));
  }

  /**
   * Crea una instancia con valores por defecto.
   * @param {Object} overrides - Valores que sobrescribir los defaults
   * @returns {$EntityPascal} Nueva instancia con defaults
   */
  static createDefault(overrides = {}) {
    const defaultData = {
      id: \`\${Date.now()}-\${Math.random().toString(36).substr(2, 9)}\`,
      active: true,
      createdAt: new Date(),
      updatedAt: new Date(),
      deletedAt: null,
      ownedBy: null,
      ...overrides
    };
    return this.create(defaultData);
  }
}
EOF
}

# Main execution
confirm_file_overwrite
write_factory_file

echo "✅ Fábrica generada: $factory_file"
