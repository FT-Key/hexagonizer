#!/bin/bash
# generator/project/09-create-public-routes.sh

set -e
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "$SCRIPT_DIR/../.." && pwd)"
source "$PROJECT_ROOT/generator/common/confirm-action.sh"

mkdir -p src/interfaces/http/public

write_file_with_confirm "src/interfaces/http/public/public.routes.js" "$(
  cat <<'EOF'
import express from 'express';

const router = express.Router();

router.get('/info', (req, res) => {
  res.json({ app: 'Hexagonizer', version: '1.0.0', description: 'Información pública' });
});

export default router;
EOF
)"
