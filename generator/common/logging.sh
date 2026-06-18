#!/bin/bash
# generator/common/logging.sh
# Funciones compartidas de logging y colores para todos los generadores

if [[ -z "${_LOGGING_SH_SOURCED:-}" ]]; then
  readonly _LOGGING_SH_SOURCED=true

  readonly RED='\033[0;31m'
  readonly GREEN='\033[0;32m'
  readonly YELLOW='\033[1;33m'
  readonly BLUE='\033[0;34m'
  readonly CYAN='\033[0;36m'
  readonly MAGENTA='\033[0;35m'
  readonly PURPLE='\033[0;35m'
  readonly WHITE='\033[1;37m'
  readonly BOLD='\033[1m'
  readonly NC='\033[0m'

  log() {
    local level="$1"
    shift
    local message="$*"

    case "$level" in
      "INFO")    echo -e "${BLUE}  →${NC} $message" ;;
      "SUCCESS") echo -e "${GREEN}  ✔${NC} $message" ;;
      "WARN")    echo -e "${YELLOW}  ⚠${NC} $message" ;;
      "ERROR")   echo -e "${RED}  ✘${NC} $message" >&2 ;;
      "INPUT")   echo -e "${CYAN}  ?${NC} $message" ;;
      "DEBUG")   echo -e "${MAGENTA}  ·${NC} $message" ;;
    esac
  }
fi
