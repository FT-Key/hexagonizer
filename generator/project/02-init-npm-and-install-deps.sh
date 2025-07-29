#!/bin/bash
# generator/project/02-init-npm-and-install-deps.sh

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
# UTILITY FUNCTIONS
# ========================

# Función para verificar si una dependencia existe en package.json
check_dependency_exists() {
  local dep_name="$1"
  grep -q "\"$dep_name\"" package.json 2>/dev/null
}

# Función para verificar si un comando está disponible
command_exists() {
  command -v "$1" &>/dev/null
}

# ========================
# INITIALIZATION FUNCTIONS
# ========================

# Inicializar proyecto npm si no existe
init_npm_project() {
  if [[ ! -f package.json ]]; then
    log "INFO" "Inicializando proyecto Node..."
    npm init -y
    log "SUCCESS" "Proyecto Node inicializado"
  else
    log "INFO" "package.json ya existe, saltando inicialización"
  fi
}

# Instalar dependencias de producción
install_production_dependencies() {
  log "INFO" "Verificando e instalando dependencias de producción..."

  # Instalar express primero (dependencia crítica)
  if ! check_dependency_exists "express"; then
    log "INFO" "Instalando express..."
    npm install express
    log "SUCCESS" "Express instalado"
  else
    log "INFO" "Express ya está instalado"
  fi

  # Lista de dependencias restantes
  local dependencies=("path-to-regexp" "cors" "helmet" "morgan" "dotenv")

  for dep in "${dependencies[@]}"; do
    if ! check_dependency_exists "$dep"; then
      log "INFO" "Instalando $dep..."
      npm install "$dep"
      log "SUCCESS" "$dep instalado"
    else
      log "INFO" "$dep ya está instalado"
    fi
  done
}

# Instalar dependencias de desarrollo
install_dev_dependencies() {
  log "INFO" "Verificando dependencias de desarrollo..."

  if ! check_dependency_exists "nodemon"; then
    log "INFO" "Instalando nodemon (dev)..."
    npm install --save-dev nodemon
    log "SUCCESS" "Nodemon instalado"
  else
    log "INFO" "Nodemon ya está instalado"
  fi
}

# Crear archivos de entorno
create_env_files() {
  log "INFO" "Verificando archivos de entorno..."

  local env_files=(".env" ".env.production")

  for env_file in "${env_files[@]}"; do
    if [[ ! -f "$env_file" ]]; then
      log "INFO" "Creando archivo $env_file"
      echo "# Variables de entorno" >"$env_file"
      log "SUCCESS" "Archivo $env_file creado"
    else
      log "INFO" "Archivo $env_file ya existe"
    fi
  done
}

# Actualizar package.json con scripts y configuraciones
update_package_json() {
  log "INFO" "Verificando scripts y configuraciones en package.json..."

  if ! node -e '
    const fs = require("fs");
    const path = "./package.json";
    try {
      const pkg = JSON.parse(fs.readFileSync(path, "utf8"));
      pkg.scripts = pkg.scripts || {};
      if (!pkg.scripts.start) pkg.scripts.start = "node src/index.js";
      if (!pkg.scripts.dev) pkg.scripts.dev = "nodemon src/index.js";
      if (pkg.type !== "module") pkg.type = "module";
      fs.writeFileSync(path, JSON.stringify(pkg, null, 2) + "\n");
      console.log("package.json actualizado con scripts y type: module");
    } catch (err) {
      console.error("Error leyendo o escribiendo package.json:", err);
      process.exit(1);
    }
  '; then
    log "ERROR" "Error actualizando package.json"
    return 1
  fi

  log "SUCCESS" "package.json actualizado correctamente"
}

# Verificar compatibilidad de versiones de Node.js
check_node_version() {
  log "INFO" "Verificando compatibilidad de versiones de Node.js..."

  local local_version
  local_version=$(node -v | sed 's/v//')
  log "INFO" "Versión actual de Node.js: $local_version"

  if ! command_exists "jq"; then
    log "WARN" "El comando 'jq' no está disponible. No se puede verificar la última versión LTS de Node.js"
    return 0
  fi

  log "INFO" "Consultando última versión LTS de Node.js..."
  local latest_version
  latest_version=$(curl -s https://nodejs.org/dist/index.json | jq -r '[.[] | select(.lts != false)][0].version' | sed 's/v//' 2>/dev/null)

  if [[ -z "$latest_version" ]]; then
    log "WARN" "No se pudo obtener la última versión estable de Node.js para comparación"
    return 0
  fi

  log "INFO" "Última versión LTS disponible: $latest_version"

  if [[ "$local_version" != "$latest_version" ]]; then
    log "WARN" "Tu versión de Node.js ($local_version) difiere de la última LTS ($latest_version)"
    log "WARN" "Considera actualizar tu entorno si encuentras problemas de compatibilidad con dependencias modernas"
  else
    log "SUCCESS" "Estás usando la última versión estable de Node.js"
  fi
}

# ========================
# MAIN FUNCTION
# ========================
main() {
  log "INFO" "Iniciando configuración del proyecto Node.js..."

  # Ejecutar funciones en orden
  init_npm_project
  install_production_dependencies
  install_dev_dependencies
  create_env_files
  update_package_json
  check_node_version

  log "SUCCESS" "Configuración de proyecto completada exitosamente"
}

# ========================
# EXECUTION LOGIC
# ========================
# Si se llama directamente con bash
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
  main "$@"
fi

# Si se hace source y hay condiciones específicas
if [[ "${BASH_SOURCE[0]}" != "${0}" && (-n "${CREATE_QUERY_UTILS:-}" || $# -gt 0) ]]; then
  main "$@"
fi
