#!/bin/bash
# shellcheck disable=SC2154
# 1.7 CONSTANTS (src/domain/$entity/constants.js) y MOCKS (src/domain/$entity/mocks.js)

constants_file="src/domain/$entity/constants.js"
mocks_file="src/domain/$entity/mocks.js"

# CONSTANTS
if [[ -f "$constants_file" && "$AUTO_CONFIRM" != true ]]; then
  read -r -p "⚠️  El archivo $constants_file ya existe. ¿Desea sobrescribirlo? [y/n]: " confirm
  if [[ ! "$confirm" =~ ^[Yy]$ ]]; then
    echo "⏭️  Se omitió la generación de $constants_file"
  else
    cat <<EOF >"$constants_file"
// Constantes relacionadas con $EntityPascal

export const DEFAULT_ACTIVE = true;
EOF
    echo "✅ Constantes generadas: $constants_file"
  fi
elif [[ ! -f "$constants_file" || "$AUTO_CONFIRM" == true ]]; then
  cat <<EOF >"$constants_file"
// Constantes relacionadas con $EntityPascal

export const DEFAULT_ACTIVE = true;
EOF
  echo "✅ Constantes generadas: $constants_file"
fi

# MOCKS
if [[ -f "$mocks_file" && "$AUTO_CONFIRM" != true ]]; then
  read -r -p "⚠️  El archivo $mocks_file ya existe. ¿Desea sobrescribirlo? [y/n]: " confirm
  if [[ ! "$confirm" =~ ^[Yy]$ ]]; then
    echo "⏭️  Se omitió la generación de $mocks_file"
  else
    cat <<EOF >"$mocks_file"
// Mocks y datos de prueba para $EntityPascal

export const mock${EntityPascal} = {
  id: 'mock-id-123',
  active: true,
  createdAt: new Date().toISOString(),
  updatedAt: new Date().toISOString(),
  deletedAt: null,
  ownedBy: 'mock-owner',
  // Agregá acá más campos mock según la entidad
};
EOF
    echo "✅ Mocks generados: $mocks_file"
  fi
elif [[ ! -f "$mocks_file" || "$AUTO_CONFIRM" == true ]]; then
  cat <<EOF >"$mocks_file"
// Mocks y datos de prueba para $EntityPascal

export const mock${EntityPascal} = {
  id: 'mock-id-123',
  active: true,
  createdAt: new Date().toISOString(),
  updatedAt: new Date().toISOString(),
  deletedAt: null,
  ownedBy: 'mock-owner',
  // Agregá acá más campos mock según la entidad
};
EOF
  echo "✅ Mocks generados: $mocks_file"
fi
