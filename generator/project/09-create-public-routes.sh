#!/bin/bash
# generator/project/09-create-public-routes.sh

set -e
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "$SCRIPT_DIR/../.." && pwd)"

source "$SCRIPT_DIR/../common/logging.sh"
source "$PROJECT_ROOT/generator/common/confirm-action.sh"

main() {
  write_file_with_confirm "src/interfaces/http/public/public.routes.js" \
'import express from "express";

const router = express.Router();

router.get("/", (req, res) => {
  res.json({ message: "Welcome to the public API" });
});

export default router;
'
  log "SUCCESS" "Public routes created"
}

if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
  main "$@"
fi
