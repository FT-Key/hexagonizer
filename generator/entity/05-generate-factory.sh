#!/bin/bash
# shellcheck disable=SC2154
# 1.6 FACTORY (src/domain/$entity/$entity-factory.js)
factory_file="src/domain/$entity/${entity}-factory.js"

# Preguntar si sobrescribir si el archivo existe
if [[ -f "$factory_file" && "$AUTO_CONFIRM" != true ]]; then
  read -r -p "⚠️  El archivo $factory_file ya existe. ¿Desea sobrescribirlo? [y/n]: " confirm
  if [[ ! "$confirm" =~ ^[Yy]$ ]]; then
    echo "⏭️  Se omitió la generación de $factory_file"
    exit 0
  fi
fi

# Generar archivo factory
cat <<EOF >"$factory_file"
import { $EntityPascal } from './$entity.js';
import { validate${EntityPascal} } from './validate-$entity.js';

export class ${EntityPascal}Factory {
  /**
   * Crea una instancia de $EntityPascal validando los datos.
   * @param {Object} data
   * @returns {$EntityPascal}
   */
  static create(data) {
    validate${EntityPascal}(data);
    return new $EntityPascal(data);
  }
}
EOF

echo "✅ Fabrica generada: $factory_file"
