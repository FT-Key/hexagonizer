#!/bin/bash
# shellcheck disable=SC2154
# 5. ROUTES Generator

# Función principal
main() {
  # Validar que las variables necesarias estén definidas
  if [[ -z "${entity:-}" || -z "${EntityPascal:-}" ]]; then
    echo "❌ Error: Las variables 'entity' y 'EntityPascal' deben estar definidas"
    echo "Uso: $0 <entity> <EntityPascal>"
    echo "Ejemplo: $0 user User"
    return 1
  fi

  generate_routes
}

# Función para generar las rutas
generate_routes() {
  local routes_file="src/interfaces/http/$entity/${entity}.routes.js"

  # Crear directorio si no existe
  mkdir -p "$(dirname "$routes_file")"

  # Verificar si ya existe y si debe sobrescribirse
  if ! should_overwrite_file "$routes_file"; then
    echo "⏭️  Rutas omitidas: $routes_file"
    return 0
  fi

  # Generar el archivo de rutas
  create_routes_content "$routes_file"

  echo "✅ Rutas generadas: $routes_file"
}

# Función para verificar si se debe sobrescribir un archivo
should_overwrite_file() {
  local file="$1"

  if [[ -f "$file" && "$AUTO_CONFIRM" != true ]]; then
    read -r -p "⚠️  El archivo $file ya existe. ¿Deseas sobrescribirlo? [y/n]: " confirm
    [[ "$confirm" =~ ^[Yy]$ ]]
  else
    true
  fi
}

# Función para crear el contenido de las rutas
create_routes_content() {
  local routes_file="$1"

  cat <<EOF >"$routes_file"
import express from 'express';
import {
  create${EntityPascal}Controller,
  get${EntityPascal}Controller,
  update${EntityPascal}Controller,
  delete${EntityPascal}Controller,
  deactivate${EntityPascal}Controller,
  list${EntityPascal}sController,
} from './${entity}.controller.js';

const router = express.Router();

// CRUD Operations
router.post('/', create${EntityPascal}Controller);
router.get('/', list${EntityPascal}sController);
router.get('/:id', get${EntityPascal}Controller);
router.put('/:id', update${EntityPascal}Controller);
router.delete('/:id', delete${EntityPascal}Controller);

// Additional Operations
router.patch('/:id/deactivate', deactivate${EntityPascal}Controller);

export default router;
EOF
}

# Manejo de argumentos si se ejecuta directamente
parse_arguments() {
  if [[ $# -ge 2 ]]; then
    entity="$1"
    EntityPascal="$2"
  fi
}

# Ejecutar si se llama directamente
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
  parse_arguments "$@"
  main "$@"
fi

# Llamada implícita si fue sourced desde otro script
if [[ -n "${entity:-}" && -n "${EntityPascal:-}" ]]; then
  main "$@"
fi
