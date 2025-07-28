#!/bin/bash
# 01-init-npm-and-install-deps.sh

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
# PROJECT CONFIGURATION
# ========================
# Dependencias de producción (orden importa - express primero)
readonly PRODUCTION_DEPS=("express" "path-to-regexp" "cors" "helmet" "morgan" "dotenv")

# Dependencias de desarrollo
readonly DEV_DEPS=("nodemon")

# Archivos de entorno requeridos
readonly ENV_FILES=(".env" ".env.production")

# ========================
# PROJECT INITIALIZATION FUNCTIONS
# ========================
initialize_npm_project() {
  log "INFO" "Verificando inicialización del proyecto npm"

  if [[ ! -f "package.json" ]]; then
    log "INFO" "package.json no encontrado, inicializando proyecto"
    if npm init -y >/dev/null 2>&1; then
      log "SUCCESS" "Proyecto Node.js inicializado con npm init -y"
    else
      log "ERROR" "Error al inicializar proyecto npm"
      return 1
    fi
  else
    log "INFO" "package.json ya existe, continuando con instalación de dependencias"
  fi

  return 0
}

check_dependency_exists() {
  local dep_name="$1"
  local package_file="${2:-package.json}"

  if [[ ! -f "$package_file" ]]; then
    return 1
  fi

  # Buscar la dependencia en dependencies o devDependencies
  if grep -q "\"$dep_name\"" "$package_file" 2>/dev/null; then
    return 0
  fi

  return 1
}

install_production_dependencies() {
  log "INFO" "Verificando e instalando dependencias de producción"

  local installed_count=0
  local skipped_count=0

  for dep in "${PRODUCTION_DEPS[@]}"; do
    if check_dependency_exists "$dep"; then
      log "INFO" "Dependencia '$dep' ya instalada, omitiendo"
      ((skipped_count++))
    else
      log "INFO" "Instalando dependencia de producción: $dep"
      if npm install "$dep" >/dev/null 2>&1; then
        log "SUCCESS" "Dependencia '$dep' instalada correctamente"
        ((installed_count++))
      else
        log "ERROR" "Error instalando dependencia '$dep'"
        return 1
      fi
    fi
  done

  log "SUCCESS" "Dependencias de producción procesadas (instaladas: $installed_count, omitidas: $skipped_count)"
  return 0
}

install_development_dependencies() {
  log "INFO" "Verificando e instalando dependencias de desarrollo"

  local installed_count=0
  local skipped_count=0

  for dep in "${DEV_DEPS[@]}"; do
    if check_dependency_exists "$dep"; then
      log "INFO" "Dependencia de desarrollo '$dep' ya instalada, omitiendo"
      ((skipped_count++))
    else
      log "INFO" "Instalando dependencia de desarrollo: $dep"
      if npm install --save-dev "$dep" >/dev/null 2>&1; then
        log "SUCCESS" "Dependencia de desarrollo '$dep' instalada correctamente"
        ((installed_count++))
      else
        log "ERROR" "Error instalando dependencia de desarrollo '$dep'"
        return 1
      fi
    fi
  done

  log "SUCCESS" "Dependencias de desarrollo procesadas (instaladas: $installed_count, omitidas: $skipped_count)"
  return 0
}

create_environment_files() {
  log "INFO" "Creando archivos de configuración de entorno"

  local created_count=0
  local skipped_count=0

  for env_file in "${ENV_FILES[@]}"; do
    if [[ ! -f "$env_file" ]]; then
      log "INFO" "Creando archivo de entorno: $env_file"
      if echo "# Variables de entorno para $(basename "$env_file" .env)" >"$env_file"; then
        log "SUCCESS" "Archivo '$env_file' creado correctamente"
        ((created_count++))
      else
        log "ERROR" "Error creando archivo '$env_file'"
        return 1
      fi
    else
      log "INFO" "Archivo '$env_file' ya existe, omitiendo"
      ((skipped_count++))
    fi
  done

  log "SUCCESS" "Archivos de entorno procesados (creados: $created_count, omitidos: $skipped_count)"
  return 0
}

update_package_json_configuration() {
  log "INFO" "Actualizando configuración en package.json"

  if ! command -v node &>/dev/null; then
    log "ERROR" "Node.js no está disponible para actualizar package.json"
    return 1
  fi

  # Script de Node.js para actualizar package.json de forma segura
  local update_script='
const fs = require("fs");
const path = "./package.json";

try {
  const pkg = JSON.parse(fs.readFileSync(path, "utf8"));
  let changes = [];
  
  // Asegurar que existe scripts
  if (!pkg.scripts) {
    pkg.scripts = {};
    changes.push("scripts object created");
  }
  
  // Agregar script start si no existe
  if (!pkg.scripts.start) {
    pkg.scripts.start = "node src/index.js";
    changes.push("start script added");
  }
  
  // Agregar script dev si no existe
  if (!pkg.scripts.dev) {
    pkg.scripts.dev = "nodemon src/index.js";
    changes.push("dev script added");
  }
  
  // Configurar como módulo ES6 si no está configurado
  if (pkg.type !== "module") {
    pkg.type = "module";
    changes.push("type: module configured");
  }
  
  // Escribir cambios
  fs.writeFileSync(path, JSON.stringify(pkg, null, 2) + "\n");
  
  if (changes.length > 0) {
    console.log("SUCCESS: package.json updated - " + changes.join(", "));
  } else {
    console.log("INFO: package.json already properly configured");
  }
  
} catch (err) {
  console.error("ERROR: " + err.message);
  process.exit(1);
}
'

  local result
  result=$(node -e "$update_script" 2>&1)
  local exit_code=$?

  if [[ $exit_code -eq 0 ]]; then
    if [[ "$result" == SUCCESS* ]]; then
      log "SUCCESS" "${result#SUCCESS: }"
    else
      log "INFO" "${result#INFO: }"
    fi
  else
    log "ERROR" "Error actualizando package.json: ${result#ERROR: }"
    return 1
  fi

  return 0
}

verify_node_version_compatibility() {
  log "INFO" "Verificando compatibilidad de versión Node.js"

  # Obtener versión local
  local local_version
  local_version=$(node -v 2>/dev/null | sed 's/v//' || echo "unknown")

  if [[ "$local_version" == "unknown" ]]; then
    log "ERROR" "No se pudo obtener la versión de Node.js"
    return 1
  fi

  log "INFO" "Versión actual de Node.js: v$local_version"

  # Verificar si jq está disponible para comparar con LTS
  if ! command -v jq &>/dev/null; then
    log "WARN" "jq no está disponible, omitiendo verificación de versión LTS"
    log "INFO" "Para verificar versiones LTS, instala jq: apt install jq (Ubuntu/Debian) o brew install jq (macOS)"
    return 0
  fi

  log "INFO" "Consultando última versión LTS de Node.js"

  # Obtener versión LTS con timeout
  local latest_version
  latest_version=$(timeout 10s curl -s https://nodejs.org/dist/index.json 2>/dev/null |
    jq -r '[.[] | select(.lts != false)][0].version' 2>/dev/null |
    sed 's/v//' || echo "")

  if [[ -z "$latest_version" ]]; then
    log "WARN" "No se pudo obtener información de versión LTS (posible problema de conectividad)"
    return 0
  fi

  log "INFO" "Última versión LTS disponible: v$latest_version"

  if [[ "$local_version" != "$latest_version" ]]; then
    log "WARN" "Tu versión ($local_version) difiere de la LTS actual ($latest_version)"
    log "INFO" "Considera actualizar si encuentras problemas de compatibilidad"
  else
    log "SUCCESS" "Estás usando la última versión LTS de Node.js"
  fi

  return 0
}

show_help() {
  cat <<EOF
Uso: $0 [OPCIONES]

OPCIONES:
  -h, --help   Muestra esta ayuda

DESCRIPCIÓN:
  Este script configura un proyecto Node.js completo instalando dependencias
  necesarias, creando archivos de configuración y actualizando package.json.

DEPENDENCIAS INSTALADAS:
  Producción: ${PRODUCTION_DEPS[*]}
  Desarrollo: ${DEV_DEPS[*]}

ARCHIVOS CREADOS:
  ${ENV_FILES[*]}

CONFIGURACIONES:
  - Scripts npm (start, dev)
  - Tipo de módulo ES6
  - Verificación de versión Node.js

EJEMPLO:
  $0                # Instalación completa
EOF
}

# ========================
# MAIN FUNCTION
# ========================
main() {
  log "INFO" "=== CONFIGURACIÓN DE PROYECTO NODE.JS ==="

  # Verificar argumentos de ayuda
  for arg in "$@"; do
    if [[ "$arg" == "-h" || "$arg" == "--help" ]]; then
      show_help
      return 0
    fi
  done

  local start_time
  start_time=$(date +%s)

  # Ejecutar configuración paso a paso
  initialize_npm_project || {
    log "ERROR" "Error inicializando proyecto npm"
    return 1
  }

  install_production_dependencies || {
    log "ERROR" "Error instalando dependencias de producción"
    return 1
  }

  install_development_dependencies || {
    log "ERROR" "Error instalando dependencias de desarrollo"
    return 1
  }

  create_environment_files || {
    log "ERROR" "Error creando archivos de entorno"
    return 1
  }

  update_package_json_configuration || {
    log "ERROR" "Error actualizando configuración de package.json"
    return 1
  }

  verify_node_version_compatibility || {
    log "WARN" "Advertencias en verificación de versión Node.js (no crítico)"
  }

  local end_time
  end_time=$(date +%s)
  local duration=$((end_time - start_time))

  log "SUCCESS" "=== CONFIGURACIÓN DE PROYECTO COMPLETADA ==="
  log "SUCCESS" "Tiempo total: ${duration}s"
  log "INFO" "El proyecto está listo para desarrollo con 'npm run dev'"
}

# ========================
# EXECUTION LOGIC
# ========================
# Si se llama directamente con bash
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
  main "$@"
fi

# Si se hace source y hay condiciones específicas
if [[ "${BASH_SOURCE[0]}" != "${0}" && (-n "${CREATE_MIDDLEWARES:-}" || $# -gt 0) ]]; then
  main "$@"
fi
