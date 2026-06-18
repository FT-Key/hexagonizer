#!/bin/bash
# hexagonizer/project/14-setup-docker.sh
# shellcheck disable=SC1091

set -e

source "$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)/../common/logging.sh"

# ========================
# INITIALIZATION
# ========================
init_environment() {
  PROJECT_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
  local confirm_script="$PROJECT_ROOT/generator/common/confirm-action.sh"
  if [[ -f "$confirm_script" ]]; then
    source "$confirm_script"
  else
    log "ERROR" "confirm-action.sh no encontrado"
    return 1
  fi
}

# ========================
# FILE EXISTENCE CHECKS
# ========================
check_existing_docker_files() {
  local existing=()
  [[ -f "./Dockerfile" ]] && existing+=("Dockerfile")
  [[ -f "./docker-compose.yml" ]] && existing+=("docker-compose.yml")
  [[ -f "./.dockerignore" ]] && existing+=(".dockerignore")

  if [[ ${#existing[@]} -gt 0 ]]; then
    if [[ "$AUTO_YES" != true ]]; then
      confirm_action "Ya existe configuración Docker. ¿Sobrescribir? (y/n): " || { SHOULD_CREATE_DOCKER=false; return 0; }
    fi
  fi
  SHOULD_CREATE_DOCKER=true
}

# ========================
# DOCKER FILE CONTENT GENERATORS
# ========================
generate_dockerfile_content() {
  cat <<'EOF'
FROM node:18

WORKDIR /app

COPY package*.json ./

RUN npm install

COPY . .

EXPOSE 3000

CMD ["npm", "start"]
EOF
}

generate_docker_compose_content() {
  cat <<'EOF'
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
}

generate_dockerignore_content() {
  cat <<'EOF'
node_modules
npm-debug.log
.DS_Store
.env
EOF
}

# ========================
# DOCKER FILE CREATION
# ========================
create_docker_files() {
  generate_dockerfile_content > "./Dockerfile"
  generate_docker_compose_content > "./docker-compose.yml"
  generate_dockerignore_content > "./.dockerignore"
  log "SUCCESS" "Archivos Docker creados"
}

# ========================
# MAIN FUNCTION
# ========================
main() {
  init_environment || exit 1
  [[ "$SETUP_DOCKER" != true ]] && exit 0

  check_existing_docker_files
  [[ "$SHOULD_CREATE_DOCKER" != true ]] && exit 0

  create_docker_files
  log "SUCCESS" "Configuración Docker generada"
}

# ========================
# EXECUTION LOGIC
# ========================
# Si se llama directamente con bash
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
  main "$@"
fi

# Si se hace source y hay condiciones específicas
if [[ "${BASH_SOURCE[0]}" != "${0}" && (-n "${SETUP_DOCKER:-}" || $# -gt 0) ]]; then
  main "$@"
fi
