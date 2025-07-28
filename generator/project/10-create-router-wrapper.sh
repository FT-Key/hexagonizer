#!/bin/bash
# generator/project/10-create-router-wrapper.sh

set -e
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "$SCRIPT_DIR/../.." && pwd)"
source "$PROJECT_ROOT/generator/common/confirm-action.sh"

mkdir -p src/utils

write_file_with_confirm "src/utils/wrap-router-with-flexible-middlewares.js" "$(
  cat <<'EOF'
import express from 'express';
import { match } from 'path-to-regexp';

export function wrapRouterWithFlexibleMiddlewares(router, options = {}) {
  const {
    globalMiddlewares = [],
    excludePathsByMiddleware = {},
    routeMiddlewares = {},
  } = options;

  const wrapped = express.Router();

  globalMiddlewares.forEach((mw) => {
    const mwName = mw.name || 'anonymous';
    wrapped.use((req, res, next) => {
      const excludes = excludePathsByMiddleware[mwName] || [];
      if (excludes.some(path => match(path)(req.path))) {
        return next();
      }
      return mw(req, res, next);
    });
  });

  wrapped.use((req, res, next) => {
    for (const pattern in routeMiddlewares) {
      const isMatch = match(pattern)(req.path);
      if (isMatch) {
        const mws = routeMiddlewares[pattern];
        let i = 0;
        const run = (i) => {
          if (i >= mws.length) return next();
          mws[i](req, res, () => run(i + 1));
        };
        return run(0);
      }
    }
    return next();
  });

  wrapped.use(router);
  return wrapped;
}
EOF
)"
