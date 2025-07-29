#!/bin/bash
# hexagonizer/project/14-setup-docker.sh
# shellcheck disable=SC1091

set -e

# ========================
# COLORES PARA OUTPUT
# ========================
if [[ -z "${RED:-}" ]]; then
  readonly RED='\033[0;31m'
  readonly GREEN='\033[0;32m'
  readonly YELLOW='\033[1;33m'
  readonly BLUE='\033[0;34m'
  readonly NC='\033[0m' # No Color
fi

# ========================
# LOGGING FUNCTION
# ========================
log() {
  local level="$1"
  shift
  local message="$*"
  local timestamp
  timestamp=$(date '+%Y-%m-%d %H:%M:%S')

  case "$level" in
  "INFO") printf "${BLUE}[INFO]${NC}    %s - %s\n" "$timestamp" "$message" ;;
  "SUCCESS") printf "${GREEN}[SUCCESS]${NC} %s - %s\n" "$timestamp" "$message" ;;
  "WARN") printf "${YELLOW}[WARN]${NC}    %s - %s\n" "$timestamp" "$message" ;;
  "ERROR") printf "${RED}[ERROR]${NC}   %s - %s\n" "$timestamp" "$message" >&2 ;;
  esac
}

# ========================
# INITIALIZATION
# ========================
init_environment() {
  SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
  PROJECT_ROOT="$(cd "$SCRIPT_DIR/../.." && pwd)"

  # Definir rutas de archivos Docker
  DOCKERFILE="./Dockerfile"
  DOCKER_COMPOSE="./docker-compose.yml"
  DOCKERIGNORE="./.dockerignore"

  log "INFO" "Inicializando entorno para configuración Docker"
  log "INFO" "Directorio del script: $SCRIPT_DIR"
  log "INFO" "Directorio raíz del proyecto: $PROJECT_ROOT"
  log "INFO" "Archivos Docker a generar:"
  log "INFO" "  - Dockerfile: $DOCKERFILE"
  log "INFO" "  - Docker Compose: $DOCKER_COMPOSE"
  log "INFO" "  - Docker Ignore: $DOCKERIGNORE"

  # Source del archivo de confirmación
  local confirm_script="$PROJECT_ROOT/generator/common/confirm-action.sh"
  if [[ -f "$confirm_script" ]]; then
    source "$confirm_script"
    log "SUCCESS" "Archivo confirm-action.sh cargado correctamente"
  else
    log "ERROR" "No se encontró el archivo confirm-action.sh: $confirm_script"
    return 1
  fi
}

# ========================
# USER INTERACTION
# ========================
ask_user_for_docker_setup() {
  log "INFO" "Verificando si el usuario desea configurar Docker"

  if [[ "$AUTO_YES" == true ]]; then
    log "INFO" "Modo automático habilitado, configurando Docker sin confirmación"
    SETUP_DOCKER=true
  else
    log "INFO" "Solicitando confirmación del usuario para configurar Docker"
    read -r -p "🐳 ¿Deseas agregar configuración Docker al proyecto? (y/n): " docker_response
    docker_response=${docker_response,,}
    SETUP_DOCKER=false
    [[ "$docker_response" =~ ^(y|yes|s|si)$ ]] && SETUP_DOCKER=true

    if [[ "$SETUP_DOCKER" == true ]]; then
      log "SUCCESS" "Usuario confirmó configuración Docker"
    else
      log "INFO" "Usuario declinó configuración Docker"
    fi
  fi
}

# ========================
# FILE EXISTENCE CHECKS
# ========================
check_existing_docker_files() {
  log "INFO" "Verificando archivos Docker existentes"

  local existing_files=()

  [[ -f "$DOCKERFILE" ]] && existing_files+=("$DOCKERFILE")
  [[ -f "$DOCKER_COMPOSE" ]] && existing_files+=("$DOCKER_COMPOSE")
  [[ -f "$DOCKERIGNORE" ]] && existing_files+=("$DOCKERIGNORE")

  if [[ ${#existing_files[@]} -gt 0 ]]; then
    log "WARN" "Se encontraron ${#existing_files[@]} archivo(s) Docker existente(s):"
    for file in "${existing_files[@]}"; do
      log "WARN" "  - $file"
    done

    if [[ "$AUTO_YES" == true ]]; then
      log "WARN" "Modo automático habilitado, sobrescribiendo archivos existentes"
      SHOULD_CREATE_DOCKER=true
    else
      log "INFO" "Solicitando confirmación para sobrescribir archivos existentes"
      if confirm_action "🛠️  Ya existe configuración Docker. ¿Deseas sobrescribirla?"; then
        log "SUCCESS" "Usuario confirmó sobrescritura de archivos Docker"
        SHOULD_CREATE_DOCKER=true
      else
        log "INFO" "Usuario declinó sobrescritura de archivos Docker"
        SHOULD_CREATE_DOCKER=false
      fi
    fi
  else
    log "SUCCESS" "No se encontraron archivos Docker existentes"
    SHOULD_CREATE_DOCKER=true
  fi
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
create_dockerfile() {
  local content
  content=$(generate_dockerfile_content)

  log "INFO" "Creando Dockerfile: $DOCKERFILE"

  if echo "$content" >"$DOCKERFILE"; then
    log "SUCCESS" "Dockerfile creado correctamente"
  else
    log "ERROR" "Error al crear Dockerfile"
    return 1
  fi
}

create_docker_compose() {
  local content
  content=$(generate_docker_compose_content)

  log "INFO" "Creando Docker Compose: $DOCKER_COMPOSE"

  if echo "$content" >"$DOCKER_COMPOSE"; then
    log "SUCCESS" "Docker Compose creado correctamente"
  else
    log "ERROR" "Error al crear Docker Compose"
    return 1
  fi
}

create_dockerignore() {
  local content
  content=$(generate_dockerignore_content)

  log "INFO" "Creando .dockerignore: $DOCKERIGNORE"

  if echo "$content" >"$DOCKERIGNORE"; then
    log "SUCCESS" ".dockerignore creado correctamente"
  else
    log "ERROR" "Error al crear .dockerignore"
    return 1
  fi
}

# ========================
# DOCKER FILES ORCHESTRATION
# ========================
create_all_docker_files() {
  log "INFO" "Iniciando creación de archivos Docker"

  local failed=0
  local created_files=()

  # Crear Dockerfile
  if create_dockerfile; then
    created_files+=("$DOCKERFILE")
  else
    ((failed++))
  fi

  # Crear Docker Compose
  if create_docker_compose; then
    created_files+=("$DOCKER_COMPOSE")
  else
    ((failed++))
  fi

  # Crear .dockerignore
  if create_dockerignore; then
    created_files+=("$DOCKERIGNORE")
  else
    ((failed++))
  fi

  if [ $failed -gt 0 ]; then
    log "ERROR" "$failed archivo(s) Docker fallaron al crearse"
    return 1
  else
    log "SUCCESS" "Todos los archivos Docker fueron creados correctamente"
    log "SUCCESS" "Archivos generados:"
    for file in "${created_files[@]}"; do
      log "SUCCESS" "  - $file"
    done
    return 0
  fi
}

# ========================
# MAIN FUNCTION
# ========================
main() {
  log "INFO" "Iniciando proceso de configuración Docker"

  # Inicializar entorno
  if ! init_environment; then
    log "ERROR" "Error en la inicialización del entorno"
    exit 1
  fi

  # Preguntar al usuario si desea configurar Docker
  ask_user_for_docker_setup

  # Si el usuario no quiere Docker, salir limpiamente
  if [[ "$SETUP_DOCKER" != true ]]; then
    log "INFO" "Configuración Docker saltada por elección del usuario"
    exit 0
  fi

  # Verificar archivos existentes y confirmar sobrescritura
  check_existing_docker_files

  # Si no se debe crear, salir limpiamente
  if [[ "$SHOULD_CREATE_DOCKER" != true ]]; then
    log "INFO" "Configuración Docker no modificada por elección del usuario"
    exit 0
  fi

  # Crear todos los archivos Docker
  if ! create_all_docker_files; then
    log "ERROR" "Error al crear configuración Docker"
    exit 1
  fi

  log "SUCCESS" "Proceso de configuración Docker completado exitosamente"
  log "SUCCESS" "Configuración Docker generada y lista para usar"
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
