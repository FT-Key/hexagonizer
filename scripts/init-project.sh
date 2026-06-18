#!/bin/bash
# init-project.sh
# shellcheck disable=SC1091 disable=SC2034

set -e

source "$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)/../generator/common/logging.sh"

declare -A MODULE_DESCRIPTIONS=(
  ["01-check-node-and-npm.sh"]="Setting up Node.js project"
  ["03-create-folders.sh"]="Creating directory structure"
  ["04-create-base-files.sh"]="Creating project base files"
  ["05-create-index.sh"]="Creating entry point"
  ["06-create-server.sh"]="Creating Express server"
  ["07-create-html.sh"]="Creating home page"
  ["08-create-health-routes.sh"]="Creating health routes"
  ["09-create-public-routes.sh"]="Creating public routes"
  ["10-create-router-wrapper.sh"]="Creating router wrapper"
  ["11-generate-base-middlewares.sh"]="Creating middlewares"
  ["12-generate-query-utils.sh"]="Generating query utilities"
  ["13-generate-database-config.sh"]="Configuring database"
  ["14-setup-docker.sh"]="Configuring Docker"
)

setup_environment() {
  SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
  PROJECT_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"
  export SCRIPT_DIR PROJECT_ROOT
}

parse_and_setup_args() {
  INIT_ARGS=("$@")
  export INIT_ARGS
  source "$PROJECT_ROOT/generator/project/00-parse-args.sh"
}

setup_middlewares_config() {
  source "$PROJECT_ROOT/generator/common/confirm-action.sh"

  if [[ "$AUTO_YES" == true ]]; then
    : "${CREATE_MIDDLEWARES:=true}"
    : "${SETUP_DOCKER:=true}"
  fi

  if [[ -z "${CREATE_MIDDLEWARES:-}" ]]; then
    if confirm_action "Do you want to add base middlewares (auth, role, error, etc)?"; then
      CREATE_MIDDLEWARES=true
    else
      CREATE_MIDDLEWARES=false
    fi
  fi

  if [[ -z "${SETUP_DOCKER:-}" ]]; then
    if confirm_action "Do you want to add Docker configuration to the project?"; then
      SETUP_DOCKER=true
    else
      SETUP_DOCKER=false
    fi
  fi

  export CREATE_MIDDLEWARES SETUP_DOCKER
}

execute_project_modules() {
  for script in "$PROJECT_ROOT/generator/project"/[0-9][0-9]-*.sh; do
    [[ -f "$script" ]] || continue
    local name
    name=$(basename "$script")
    [[ "$name" == "00-parse-args.sh" ]] && continue

    local desc="${MODULE_DESCRIPTIONS[$name]:-$name}"
    log "INFO" "$desc"
    bash "$script" || { log "ERROR" "Error: $desc"; return 1; }
  done
}

show_help() {
  cat <<EOF
Usage: $0 [OPTIONS]

OPTIONS:
  -y, --yes    Automatic mode, answers 'yes' to all questions
  -h, --help   Show this help
EOF
}

main() {
  for arg in "$@"; do
    if [[ "$arg" == "-h" || "$arg" == "--help" ]]; then
      show_help
      return 0
    fi
  done

  log "INFO" "=== STARTING PROJECT GENERATION ==="

  setup_environment
  parse_and_setup_args "$@"
  setup_middlewares_config
  execute_project_modules || return 1

  log "SUCCESS" "=== PROJECT GENERATED SUCCESSFULLY ==="
}

if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
  main "$@"
fi
