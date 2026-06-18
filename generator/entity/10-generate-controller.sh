#!/bin/bash
# generator/entity/10-generate-controller.sh
# shellcheck disable=SC2154
# 4. CONTROLLER Generator

source "$PROJECT_ROOT/generator/common/logging.sh"
source "$PROJECT_ROOT/generator/common/io.sh"

main() {
  if [[ -z "${entity:-}" || -z "${EntityPascal:-}" ]]; then
    log "ERROR" "Las variables 'entity' y 'EntityPascal' deben estar definidas"
    echo "Uso: $0 <entity> <EntityPascal>"
    echo "Ejemplo: $0 user User"
    return 1
  fi

  generate_controller
}

generate_controller() {
  local controller_file="src/interfaces/http/$entity/${entity}.controller.js"

  ensure_directory "$(dirname "$controller_file")"

  if confirm_overwrite "$controller_file" "controlador"; then
    create_controller_content "$controller_file"
    log "SUCCESS" "Controlador generado: $controller_file"
  fi
}

create_controller_content() {
  local controller_file="$1"

  cat <<EOF >"$controller_file"
import { Create${EntityPascal} } from '../../../application/$entity/use-cases/create-$entity.js';
import { Get${EntityPascal} } from '../../../application/$entity/use-cases/get-$entity.js';
import { Update${EntityPascal} } from '../../../application/$entity/use-cases/update-$entity.js';
import { Delete${EntityPascal} } from '../../../application/$entity/use-cases/delete-$entity.js';
import { Deactivate${EntityPascal} } from '../../../application/$entity/use-cases/deactivate-$entity.js';
import { List${EntityPascal}s } from '../../../application/$entity/use-cases/list-$entity.js';

export function create${EntityPascal}Controllers(repository) {
  return {
    create: async (req, res) => {
      const useCase = new Create${EntityPascal}(repository);
      const item = await useCase.execute(req.body);
      res.status(201).json(item);
    },

    get: async (req, res) => {
      const useCase = new Get${EntityPascal}(repository);
      const item = await useCase.execute(req.params.id);
      if (!item) return res.status(404).json({ error: '${EntityPascal} not found' });
      res.json(item);
    },

    update: async (req, res) => {
      const useCase = new Update${EntityPascal}(repository);
      const item = await useCase.execute(req.params.id, req.body);
      if (!item) return res.status(404).json({ error: '${EntityPascal} not found' });
      res.json(item);
    },

    delete: async (req, res) => {
      const useCase = new Delete${EntityPascal}(repository);
      const success = await useCase.execute(req.params.id);
      res.status(success ? 204 : 404).send();
    },

    deactivate: async (req, res) => {
      const useCase = new Deactivate${EntityPascal}(repository);
      const item = await useCase.execute(req.params.id);
      if (!item) return res.status(404).json({ error: '${EntityPascal} not found' });
      res.json(item);
    },

    list: async (req, res) => {
      try {
        const useCase = new List${EntityPascal}s(repository);
        const { filters, search, pagination, sort } = req;

        const { data, meta } = await useCase.execute({
          filters,
          search,
          pagination,
          sort,
        });

        res.status(200).json({ data, meta });
      } catch (error) {
        res.status(500).json({ error: error.message });
      }
    },
  };
}
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
