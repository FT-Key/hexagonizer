#!/bin/bash
# shellcheck disable=SC2154
# 4. CONTROLLER

controller_file="src/interfaces/http/$entity/${entity}.controller.js"
mkdir -p "$(dirname "$controller_file")"

# Preguntar si ya existe, excepto si -y
if [[ -f "$controller_file" && "$AUTO_CONFIRM" != true ]]; then
  read -r -p "⚠️  El archivo $controller_file ya existe. ¿Deseas sobrescribirlo? [y/n]: " confirm
  if [[ ! "$confirm" =~ ^[Yy]$ ]]; then
    echo "⏭️  Controlador omitido: $controller_file"
    exit 0
  fi
fi

# Generar el archivo
cat <<EOF >"$controller_file"
import { InMemory${EntityPascal}Repository } from '../../../infrastructure/$entity/in-memory-$entity-repository.js';

import { Create${EntityPascal} } from '../../../application/$entity/use-cases/create-$entity.js';
import { Get${EntityPascal} } from '../../../application/$entity/use-cases/get-$entity.js';
import { Update${EntityPascal} } from '../../../application/$entity/use-cases/update-$entity.js';
import { Delete${EntityPascal} } from '../../../application/$entity/use-cases/delete-$entity.js';
import { Deactivate${EntityPascal} } from '../../../application/$entity/use-cases/deactivate-$entity.js';
import { List${EntityPascal}s } from '../../../application/$entity/use-cases/list-$entity.js';

const repository = new InMemory${EntityPascal}Repository();

export const create${EntityPascal}Controller = async (req, res) => {
  const useCase = new Create${EntityPascal}(repository);
  const item = await useCase.execute(req.body);
  res.status(201).json(item);
};

export const get${EntityPascal}Controller = async (req, res) => {
  const useCase = new Get${EntityPascal}(repository);
  const item = await useCase.execute(req.params.id);
  if (!item) return res.status(404).json({ error: '${EntityPascal} not found' });
  res.json(item);
};

export const update${EntityPascal}Controller = async (req, res) => {
  const useCase = new Update${EntityPascal}(repository);
  const item = await useCase.execute(req.params.id, req.body);
  res.json(item);
};

export const delete${EntityPascal}Controller = async (req, res) => {
  const useCase = new Delete${EntityPascal}(repository);
  const success = await useCase.execute(req.params.id);
  res.status(success ? 204 : 404).send();
};

export const deactivate${EntityPascal}Controller = async (req, res) => {
  const useCase = new Deactivate${EntityPascal}(repository);
  const item = await useCase.execute(req.params.id);
  res.json(item);
};

export const list${EntityPascal}sController = async (req, res) => {
  const useCase = new List${EntityPascal}s(repository);
  const items = await useCase.execute({
    filters: req.filters,
    search: req.search,
    pagination: req.pagination,
    sort: req.sort,
  });
  res.json(items);
};
EOF

echo "✅ Controlador generado: $controller_file"
