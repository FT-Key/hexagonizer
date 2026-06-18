#!/bin/bash
# generator/project/01-check-node-and-npm.sh

set -e

source "$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)/../common/logging.sh"

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
  if [[ ! -f "package.json" ]]; then
    npm init -y >/dev/null 2>&1 || { log "ERROR" "Error al inicializar proyecto npm"; return 1; }
    log "SUCCESS" "Proyecto Node.js inicializado"
  fi
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
  local installed=0
  for dep in "${PRODUCTION_DEPS[@]}"; do
    if ! check_dependency_exists "$dep"; then
      npm install "$dep" >/dev/null 2>&1 || { log "ERROR" "Error instalando $dep"; return 1; }
      ((installed++))
    fi
  done
  log "SUCCESS" "Dependencias de producción instaladas ($installed nuevas)"
}
install_development_dependencies() {
  local installed=0
  for dep in "${DEV_DEPS[@]}"; do
    if ! check_dependency_exists "$dep"; then
      npm install --save-dev "$dep" >/dev/null 2>&1 || { log "ERROR" "Error instalando $dep"; return 1; }
      ((installed++))
    fi
  done
  log "SUCCESS" "Dependencias de desarrollo instaladas ($installed nuevas)"
}
create_environment_files() {
  local created=0
  for env_file in "${ENV_FILES[@]}"; do
    if [[ ! -f "$env_file" ]]; then
      echo "# Variables de entorno para $(basename "$env_file")" >"$env_file"
      ((created++))
    fi
  done
  log "SUCCESS" "Archivos de entorno creados ($created nuevos)"
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
  local local_version
  local_version=$(node -v 2>/dev/null | sed 's/v//' || echo "unknown")
  [[ "$local_version" == "unknown" ]] && return 0

  log "INFO" "Node.js v$local_version detectado"

  if command -v jq &>/dev/null; then
    local latest_version
    latest_version=$(timeout 10s curl -s https://nodejs.org/dist/index.json 2>/dev/null |
      jq -r '[.[] | select(.lts != false)][0].version' 2>/dev/null |
      sed 's/v//' || echo "")
    if [[ -n "$latest_version" && "$local_version" != "$latest_version" ]]; then
      log "WARN" "Node $local_version no es la última LTS ($latest_version) — actualiza si hay problemas"
    fi
  fi
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
  initialize_npm_project || return 1
  install_production_dependencies || return 1
  install_development_dependencies || return 1
  create_environment_files || return 1
  update_package_json_configuration || return 1
  verify_node_version_compatibility
  log "SUCCESS" "Proyecto Node.js configurado — ejecuta 'npm run dev'"
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
