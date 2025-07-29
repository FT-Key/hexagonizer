#!/bin/bash
# common-functions.sh

confirm_action() {
  local prompt="$1"

  # Permitir AUTO_YES o AUTO_CONFIRM (prioridad a AUTO_YES)
  local auto_value="${AUTO_YES:-$AUTO_CONFIRM}"

  if [ "$auto_value" = true ]; then
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

write_file_with_confirm() {
  local filepath=$1
  local content=$2

  if [[ -f "$filepath" ]]; then
    if [[ "$AUTO_YES" == true ]]; then
      echo "⚠️  El archivo $filepath ya existe. Sobrescribiendo por opción -y."
      echo "$content" >"$filepath"
    else
      if confirm_action "⚠️  El archivo $filepath ya existe. ¿Desea sobrescribirlo? (y/n): "; then
        echo "$content" >"$filepath"
      else
        echo "❌ No se sobrescribió $filepath"
        return 1
      fi
    fi
  else
    echo "$content" >"$filepath"
  fi
}
