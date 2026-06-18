#!/bin/bash
# 00-helpers.sh
# Mantenido para compatibilidad - prefiere usar io.sh directamente

source "$(cd "$(dirname "${BASH_SOURCE[0]}")/../common" && pwd)/io.sh"

confirm_action() {
  local prompt="$1"
  if $AUTO_CONFIRM; then
    result="y"
  else
    read -r -p "$prompt [y/n] " result
  fi
  [[ "$result" == "y" ]]
}
