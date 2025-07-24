#!/bin/bash
# hexagon/project/02-create-folders.sh

mkdir -p \
  src/config \
  src/domain \
  src/infrastructure \
  src/infrastructure/database \
  src/interfaces/http/health \
  src/interfaces/http/public \
  src/interfaces/http/middlewares \
  src/application \
  src/utils \
  src/public \
  tests/application \
  tests/interfaces/http/middlewares

echo "✅ Carpetas base creadas."
