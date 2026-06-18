#!/bin/bash
# generator/project/08-create-health-routes.sh

set -e
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "$SCRIPT_DIR/../.." && pwd)"

source "$SCRIPT_DIR/../common/logging.sh"
source "$PROJECT_ROOT/generator/common/confirm-action.sh"

main() {
  write_file_with_confirm "src/interfaces/http/health/health.routes.js" \
'import express from "express";

const router = express.Router();

router.get("/", (req, res) => {
  res.json({ status: "ok", timestamp: Date.now() });
});

export default router;
'
  log "SUCCESS" "Rutas de health creadas"
}

if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
  main "$@"
fi

if [[ "${BASH_SOURCE[0]}" != "${0}" && (-n "${CREATE_HEALTH_ROUTES:-}" || $# -gt 0) ]]; then
  main "$@"
fi
