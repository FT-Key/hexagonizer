#!/bin/bash
# common-functions.sh

confirm_action() {
  local prompt="$1"
  if [ "$AUTO_YES" = true ]; then
    echo "✔️ Auto confirmación activada, se asume Sí para: $prompt"
    return 0
  fi

  while true; do
    read -r -p "$prompt [y/n]: " response
    case "$response" in
    [yY]) return 0 ;;
    [nN] | "") return 1 ;;
    *) echo "Por favor ingrese 'y' o 'n'." ;;
    esac
  done
}
