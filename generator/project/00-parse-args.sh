#!/bin/bash
# generator/project/00-parse-args.sh

set -e

source "$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)/../common/logging.sh"

parse_arguments() {
  local args_to_parse=("$@")
  if [[ -n "${INIT_ARGS:-}" ]]; then
    args_to_parse=("${INIT_ARGS[@]}")
  fi
  AUTO_YES=false
  for arg in "${args_to_parse[@]}"; do
    case "$arg" in
      -y|--yes) AUTO_YES=true; break;;
      -h|--help) show_help; return 0;;
    esac
  done
  export AUTO_YES
}

show_help() {
  cat <<EOF
Uso: $0 [OPCIONES]

OPCIONES:
  -y, --yes    Modo automático
  -h, --help   Muestra esta ayuda
EOF
}

if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
  parse_arguments "$@"
fi

if [[ "${BASH_SOURCE[0]}" != "${0}" && (-n "${INIT_ARGS:-}" || $# -gt 0) ]]; then
  parse_arguments "$@"
fi
