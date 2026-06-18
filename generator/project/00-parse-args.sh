#!/bin/bash
# generator/project/00-parse-args.sh

set -e

source "$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)/../common/logging.sh"

parse_arguments() {
  local args_to_parse=("$@")
  if [[ -n "${INIT_ARGS:-}" ]]; then
    args_to_parse=("${INIT_ARGS[@]}")
  fi
  AUTO_YES=${AUTO_YES:-false}
  CREATE_MIDDLEWARES=${CREATE_MIDDLEWARES:-}
  SETUP_DOCKER=${SETUP_DOCKER:-}
  for arg in "${args_to_parse[@]}"; do
    case "$arg" in
      -y|--yes) AUTO_YES=true;;
      --middlewares) CREATE_MIDDLEWARES=true;;
      --docker) SETUP_DOCKER=true;;
      -h|--help) show_help; return 0;;
    esac
  done
  export AUTO_YES CREATE_MIDDLEWARES SETUP_DOCKER
}

show_help() {
  cat <<EOF
Usage: $0 [OPTIONS]

OPTIONS:
  -y, --yes         Automatic mode
  --middlewares     Add base middlewares
  --docker          Configure Docker
  -h, --help        Show this help
EOF
}

if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
  parse_arguments "$@"
fi
