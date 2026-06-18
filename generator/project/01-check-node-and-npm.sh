#!/bin/bash
# generator/project/01-check-node-and-npm.sh

set -e

source "$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)/../common/logging.sh"

# ========================
# PROJECT CONFIGURATION
# ========================
# Production dependencies (order matters - express first)
readonly PRODUCTION_DEPS=("express" "path-to-regexp" "cors" "helmet" "morgan" "dotenv")

# Development dependencies
readonly DEV_DEPS=("nodemon")

# Required environment files
readonly ENV_FILES=(".env" ".env.production")

# ========================
# PROJECT INITIALIZATION FUNCTIONS
# ========================
initialize_npm_project() {
  if [[ ! -f "package.json" ]]; then
    npm init -y >/dev/null 2>&1 || {     log "ERROR" "Error initializing npm project"; return 1; }
    log "SUCCESS" "Node.js project initialized"
  fi
}

check_dependency_exists() {
  local dep_name="$1"
  local package_file="${2:-package.json}"

  if [[ ! -f "$package_file" ]]; then
    return 1
  fi

  # Look for the dependency in dependencies or devDependencies
  if grep -q "\"$dep_name\"" "$package_file" 2>/dev/null; then
    return 0
  fi

  return 1
}

install_production_dependencies() {
  local installed=0
  for dep in "${PRODUCTION_DEPS[@]}"; do
    if ! check_dependency_exists "$dep"; then
      npm install "$dep" >/dev/null 2>&1 || { log "ERROR" "Error installing $dep"; return 1; }
      ((installed++))
    fi
  done
  log "SUCCESS" "Production dependencies installed ($installed new)"
}
install_development_dependencies() {
  local installed=0
  for dep in "${DEV_DEPS[@]}"; do
    if ! check_dependency_exists "$dep"; then
      npm install --save-dev "$dep" >/dev/null 2>&1 || { log "ERROR" "Error installing $dep"; return 1; }
      ((installed++))
    fi
  done
  log "SUCCESS" "Development dependencies installed ($installed new)"
}
create_environment_files() {
  local created=0
  for env_file in "${ENV_FILES[@]}"; do
    if [[ ! -f "$env_file" ]]; then
      echo "# Variables de entorno para $(basename "$env_file")" >"$env_file"
      ((created++))
    fi
  done
  log "SUCCESS" "Environment files created ($created new)"
}

update_package_json_configuration() {
  log "INFO" "Updating configuration in package.json"

  if ! command -v node &>/dev/null; then
    log "ERROR" "Node.js not available to update package.json"
    return 1
  fi

  # Node.js script to safely update package.json
  local update_script='
const fs = require("fs");
const path = "./package.json";

try {
  const pkg = JSON.parse(fs.readFileSync(path, "utf8"));
  let changes = [];
  
  // Ensure scripts object exists
  if (!pkg.scripts) {
    pkg.scripts = {};
    changes.push("scripts object created");
  }
  
  // Add start script if not present
  if (!pkg.scripts.start) {
    pkg.scripts.start = "node src/index.js";
    changes.push("start script added");
  }
  
  // Add dev script if not present
  if (!pkg.scripts.dev) {
    pkg.scripts.dev = "nodemon src/index.js";
    changes.push("dev script added");
  }
  
  // Configure as ES6 module if not set
  if (pkg.type !== "module") {
    pkg.type = "module";
    changes.push("type: module configured");
  }
  
  // Write changes
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
    log "ERROR" "Error updating package.json: ${result#ERROR: }"
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
      log "WARN" "Node $local_version is not the latest LTS ($latest_version) — update if you encounter issues"
    fi
  fi
}

show_help() {
  cat <<EOF
Usage: $0 [OPTIONS]

OPTIONS:
  -h, --help   Show this help

DESCRIPTION:
  This script configures a complete Node.js project by installing required
  dependencies, creating configuration files, and updating package.json.

INSTALLED DEPENDENCIES:
  Production: ${PRODUCTION_DEPS[*]}
  Development: ${DEV_DEPS[*]}

CREATED FILES:
  ${ENV_FILES[*]}

CONFIGURATIONS:
  - npm scripts (start, dev)
  - ES6 module type
  - Node.js version check

EXAMPLE:
  $0                # Full installation
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
  log "SUCCESS" "Node.js project configured — run 'npm run dev'"
}

# ========================
# EXECUTION LOGIC
# ========================
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
  main "$@"
fi
