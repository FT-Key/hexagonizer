#!/bin/bash
# common-functions.sh
# Kept for backward compatibility - prefer using io.sh directly

source "$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)/logging.sh"
source "$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)/io.sh"

confirm_action() {
  local prompt="$1"

  local auto_value="${AUTO_YES:-$AUTO_CONFIRM}"

  if [ "$auto_value" = true ]; then
    return 0
  fi

  while true; do
    read -r -p "$prompt [y/n]: " response
    case "$response" in
    [yY]) return 0 ;;
    [nN] | "") return 1 ;;
    *) echo "Please enter 'y' or 'n'." ;;
    esac
  done
}

write_file_with_confirm() {
  local filepath=$1
  local content=$2

  if [[ -f "$filepath" ]]; then
    if [[ "$AUTO_YES" == true ]]; then
      echo "⚠️  File $filepath already exists. Overwriting due to -y flag."
      echo "$content" >"$filepath"
    else
      if confirm_action "⚠️  File $filepath already exists. Do you want to overwrite it? (y/n): "; then
        echo "$content" >"$filepath"
      else
        echo "❌ Did not overwrite $filepath"
        return 1
      fi
    fi
  else
    echo "$content" >"$filepath"
  fi
}
