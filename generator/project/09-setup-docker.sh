#!/bin/bash
# hexagonizer/project/09-setup-docker.sh
# shellcheck disable=SC1091

# Obtener ruta absoluta al root del CLI (asumiendo que estamos en hexagonizer/project)
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "$SCRIPT_DIR/../.." && pwd)"

# Importar confirm-action desde common
source "$PROJECT_ROOT/generator/common/confirm-action.sh"

# Preguntar si desea configurar Docker
if [[ "$AUTO_YES" == true ]]; then
  SETUP_DOCKER=true
else
  read -r -p "🐳 ¿Deseas agregar configuración Docker al proyecto? (y/n): " docker_response
  docker_response=${docker_response,,}
  SETUP_DOCKER=false
  [[ "$docker_response" =~ ^(y|yes|s|si)$ ]] && SETUP_DOCKER=true
fi

if [[ "$SETUP_DOCKER" != true ]]; then
  echo "⏩ Saltando configuración Docker."
  exit 0
fi

DOCKERFILE="./Dockerfile"
DOCKER_COMPOSE="./docker-compose.yml"
DOCKERIGNORE="./.dockerignore"

should_create_docker=true

# Verificar si ya existen archivos
if [[ -f "$DOCKERFILE" || -f "$DOCKER_COMPOSE" || -f "$DOCKERIGNORE" ]]; then
  if [[ "$AUTO_YES" == true ]]; then
    echo "⚠️  Archivos Docker ya existen. Sobrescribiendo automáticamente por --yes."
  else
    confirm_action "🛠️  Ya existe configuración Docker. ¿Deseas sobrescribirla?" || should_create_docker=false
  fi
fi

if [[ "$should_create_docker" == true ]]; then
  echo "⚙️  Generando configuración Docker..."

  cat <<'EOF' >"$DOCKERFILE"
FROM node:18

WORKDIR /app

COPY package*.json ./

RUN npm install

COPY . .

EXPOSE 3000

CMD ["npm", "start"]
EOF

  cat <<'EOF' >"$DOCKER_COMPOSE"
version: '3.9'

services:
  app:
    build: .
    ports:
      - '3000:3000'
    volumes:
      - .:/app
      - /app/node_modules
    command: npm start
EOF

  cat <<'EOF' >"$DOCKERIGNORE"
node_modules
npm-debug.log
.DS_Store
.env
EOF

  echo "✅ Configuración Docker generada:"
  echo "  - $DOCKERFILE"
  echo "  - $DOCKER_COMPOSE"
  echo "  - $DOCKERIGNORE"
else
  echo "⏩ Configuración Docker no modificada."
fi
