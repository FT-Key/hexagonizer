#!/bin/bash
# shellcheck disable=SC2154
# shellcheck disable=SC2034
# shellcheck disable=SC1091
set -e

# Obtener ruta absoluta del directorio del script
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"

# Cargar partes con rutas absolutas
source "$PROJECT_ROOT/generator/entity/00-helpers.sh"
source "$PROJECT_ROOT/generator/entity/01-parse-args.sh" "$@"
source "$PROJECT_ROOT/generator/entity/02-load-schema.sh"

echo "🛠 Generando entidad '$entity'..."

# Crear carpetas base
mkdir -p "src/domain/$entity"
mkdir -p "src/application/$entity/use-cases"
mkdir -p "src/infrastructure/$entity"
mkdir -p "src/interfaces/http/$entity"
mkdir -p "tests/application/$entity"

# Ejecutar partes de generación, que leen la variable $FIELDS_JSON para campos
source "$PROJECT_ROOT/generator/entity/03-generate-domain.sh"
source "$PROJECT_ROOT/generator/entity/04-generate-validation.sh"
source "$PROJECT_ROOT/generator/entity/05-generate-factory.sh"
source "$PROJECT_ROOT/generator/entity/06-generate-constants.sh"
source "$PROJECT_ROOT/generator/entity/07-generate-repository.sh"
source "$PROJECT_ROOT/generator/entity/08-generate-usecases.sh"
source "$PROJECT_ROOT/generator/entity/09-generate-services.sh"
source "$PROJECT_ROOT/generator/entity/10-generate-controller.sh"
source "$PROJECT_ROOT/generator/entity/11-generate-routes.sh"
source "$PROJECT_ROOT/generator/entity/12-generate-query-entity-config.sh"
source "$PROJECT_ROOT/generator/entity/13-generate-query-middlewares-and-utils.sh"
source "$PROJECT_ROOT/generator/entity/14-generate-tests.sh"
source "$PROJECT_ROOT/generator/entity/15-update-index.sh"

echo "✔️  Estructura generada para '$entity'"
