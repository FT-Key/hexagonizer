#!/bin/bash
# generator/project/11-generate-query-utils.sh

# Obtener raíz del proyecto real
PROJECT_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"

# Ejecutar el generador desde common/
bash "$PROJECT_ROOT/generator/common/generate-query-utils.sh" "$@"
