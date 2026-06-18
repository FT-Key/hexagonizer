#!/bin/bash
# generator/project/12-generate-query-utils.sh

set -e

source "$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)/../common/logging.sh"

main() {
  local script="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)/../common/generate-query-utils.sh"
  bash "$script" "$@" || exit 1
}

if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
  main "$@"
fi
