#!/bin/bash
# generator/project/10-create-router-wrapper.sh

set -e
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "$SCRIPT_DIR/../.." && pwd)"

source "$SCRIPT_DIR/../common/logging.sh"
source "$PROJECT_ROOT/generator/common/confirm-action.sh"

main() {
  write_file_with_confirm "src/utils/wrap-router-with-flexible-middlewares.js" \
'export function wrapRouterWithFlexibleMiddlewares(router, { globalMiddlewares = [], excludePathsByMiddleware = {}, routeMiddlewares = {} } = {}) {
  return router;
}
'
  log "SUCCESS" "Wrapper de router creado"
}

if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
  main "$@"
fi
