#!/bin/bash
# generator/entity/11-generate-routes.sh
# shellcheck disable=SC2154
# 5. ROUTES Generator

source "$PROJECT_ROOT/generator/common/logging.sh"
source "$PROJECT_ROOT/generator/common/io.sh"

main() {
  if [[ -z "${entity:-}" || -z "${EntityPascal:-}" ]]; then
    log "ERROR" "Las variables 'entity' y 'EntityPascal' deben estar definidas"
    echo "Uso: $0 <entity> <EntityPascal>"
    echo "Ejemplo: $0 user User"
    return 1
  fi

  generate_routes
}

generate_routes() {
  local routes_file="src/interfaces/http/$entity/${entity}.routes.js"

  ensure_directory "$(dirname "$routes_file")"

  if ! confirm_overwrite "$routes_file" "rutas"; then
    return 0
  fi

  create_routes_content "$routes_file"
  log "SUCCESS" "Rutas generadas: $routes_file"
}

create_routes_content() {
  local routes_file="$1"

  cat <<EOF >"$routes_file"
import express from 'express';
import { InMemory${EntityPascal}Repository } from '../../infrastructure/$entity/in-memory-$entity-repository.js';
import { create${EntityPascal}Controllers } from './${entity}.controller.js';

const repository = new InMemory${EntityPascal}Repository();
const controllers = create${EntityPascal}Controllers(repository);

const router = express.Router();

// CRUD Operations
router.post('/', controllers.create);
router.get('/', controllers.list);
router.get('/:id', controllers.get);
router.put('/:id', controllers.update);
router.delete('/:id', controllers.delete);

// Additional Operations
router.patch('/:id/deactivate', controllers.deactivate);

export default router;
EOF
}

parse_arguments() {
  if [[ $# -ge 2 ]]; then
    entity="$1"
    EntityPascal="$2"
  fi
}

if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
  parse_arguments "$@"
  main "$@"
fi

if [[ -n "${entity:-}" && -n "${EntityPascal:-}" ]]; then
  main "$@"
fi
