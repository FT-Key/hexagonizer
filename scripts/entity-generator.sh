#!/bin/bash
# shellcheck disable=SC2154
# shellcheck disable=SC2034
# shellcheck disable=SC1091
set -e

# Obtener ruta absoluta del directorio del script
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"

# Cargar partes con rutas absolutas
source "$PROJECT_ROOT/hexagon/entity/00-helpers.sh"
source "$PROJECT_ROOT/hexagon/entity/01-parse-args.sh" "$@"
source "$PROJECT_ROOT/hexagon/entity/02-load-schema.sh"

echo "🛠 Generando entidad '$entity'..."

# Unir campos base + custom
base_fields='[
  { "name": "id", "required": true },
  { "name": "active", "default": true },
  { "name": "createdAt", "default": "new Date()" },
  { "name": "updatedAt", "default": "new Date()" },
  { "name": "deletedAt", "default": null },
  { "name": "ownedBy", "default": null }
]'

tmp_base=$(mktemp)
tmp_custom=$(mktemp)

echo "$base_fields" >"$tmp_base"
echo "$custom_fields" >"$tmp_custom"
fields=$(jq -s '.[0] + .[1]' "$tmp_base" "$tmp_custom")

rm "$tmp_base" "$tmp_custom"

# Crear carpetas base
mkdir -p "src/domain/$entity"
mkdir -p "src/application/$entity/use-cases"
mkdir -p "src/infrastructure/$entity"
mkdir -p "src/interfaces/http/$entity"
mkdir -p "tests/application/$entity"

# Ejecutar partes de generación
source "$PROJECT_ROOT/hexagon/entity/03-generate-domain.sh"
source "$PROJECT_ROOT/hexagon/entity/04-generate-validation.sh"
source "$PROJECT_ROOT/hexagon/entity/05-generate-factory.sh"
source "$PROJECT_ROOT/hexagon/entity/06-generate-constants.sh"
source "$PROJECT_ROOT/hexagon/entity/07-generate-repository.sh"
source "$PROJECT_ROOT/hexagon/entity/08-generate-usecases.sh"
source "$PROJECT_ROOT/hexagon/entity/09-generate-services.sh"
source "$PROJECT_ROOT/hexagon/entity/10-generate-controller.sh"
source "$PROJECT_ROOT/hexagon/entity/11-generate-routes.sh"
source "$PROJECT_ROOT/hexagon/entity/12-generate-query-entity-config.sh"
source "$PROJECT_ROOT/hexagon/entity/13-generate-query-middlewares-and-utils.sh"
source "$PROJECT_ROOT/hexagon/entity/14-generate-tests.sh"
source "$PROJECT_ROOT/hexagon/entity/15-update-index.sh"

echo "✔️  Estructura generada para '$entity'"
