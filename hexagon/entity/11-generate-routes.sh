#!/bin/bash
# shellcheck disable=SC2154
# 5. ROUTES

routes_file="src/interfaces/http/$entity/${entity}.routes.js"
mkdir -p "$(dirname "$routes_file")"

# Verificar si ya existe y si debe sobrescribirse
if [[ -f "$routes_file" && "$AUTO_CONFIRM" != true ]]; then
  read -r -p "⚠️  El archivo $routes_file ya existe. ¿Deseas sobrescribirlo? [y/n]: " confirm
  if [[ ! "$confirm" =~ ^[Yy]$ ]]; then
    echo "⏭️  Rutas omitidas: $routes_file"
    exit 0
  fi
fi

# Generar archivo de rutas
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

router.post('/', create${EntityPascal}Controller);
router.get('/', list${EntityPascal}sController);
router.get('/:id', get${EntityPascal}Controller);
router.put('/:id', update${EntityPascal}Controller);
router.delete('/:id', delete${EntityPascal}Controller);
router.patch('/:id/deactivate', deactivate${EntityPascal}Controller);

export default router;
EOF

echo "✅ Rutas generadas: $routes_file"
