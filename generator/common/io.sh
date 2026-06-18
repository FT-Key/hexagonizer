#!/bin/bash
# generator/common/io.sh
# Shared I/O, validation and utility functions for all generators

if [[ -z "${_IO_SH_SOURCED:-}" ]]; then
  readonly _IO_SH_SOURCED=true

  pluralize() {
    local word="$1"
    case "$word" in
      *[aeiou]) echo "${word}s" ;;
      *[zs])    echo "${word}es" ;;
      *y)       echo "${word%y}ies" ;;
      *)        echo "${word}s" ;;
    esac
  }

  validate_entity() {
    local entity="$1"
    if [[ -z "$entity" ]]; then
      log "ERROR" "Entity name cannot be empty"
      return 1
    fi
    if [[ ! "$entity" =~ ^[a-zA-Z][a-zA-Z0-9_-]*$ ]]; then
      log "ERROR" "Entity name must start with a letter and contain only letters, numbers, hyphens, and underscores"
      return 1
    fi
    return 0
  }

  ensure_directory() {
    local dir_path="$1"
    if ! mkdir -p "$dir_path" 2>/dev/null; then
      log "ERROR" "Could not create directory: $dir_path"
      return 1
    fi
  }

  confirm_overwrite() {
    local file_path="$1"
    local file_type="${2:-file}"
    local auto_confirm="${AUTO_CONFIRM:-false}"

    if [[ -e "$file_path" && "$auto_confirm" != "true" ]]; then
      printf "${YELLOW}⚠️  %s %s already exists. Overwrite? [y/N]: ${NC}" "$file_type" "$file_path"
      read -r confirm
      if [[ ! "$confirm" =~ ^[Yy]$ ]]; then
        log "INFO" "Skipped: $file_path"
        return 1
      fi
    fi
    return 0
  }

  write_file() {
    local content="$1"
    local file_path="$2"

    if confirm_overwrite "$file_path"; then
      if printf "%s\n" "$content" >"$file_path"; then
        log "SUCCESS" "Generated: $file_path"
        return 0
      else
        log "ERROR" "Could not write file: $file_path"
        return 1
      fi
    fi
    return 0
  }
fi
