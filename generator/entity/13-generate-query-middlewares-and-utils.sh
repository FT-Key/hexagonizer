#!/bin/bash
# hexagonizer/entity/13-generate-query-middlewares.sh
# shellcheck disable=SC1091
set -e

# Obtener ruta raíz del proyecto (asumiendo que este archivo está en hexagonizer/entity/)
PROJECT_ROOT="$(cd "$(dirname "$(dirname "$(dirname "${BASH_SOURCE[0]}")")")" && pwd)"

# Incluir scripts desde common usando ruta absoluta
source "$PROJECT_ROOT/generator/common/generate-query-middlewares.sh"
source "$PROJECT_ROOT/generator/common/generate-query-utils.sh"
