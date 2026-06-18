#!/bin/bash
# generator/common/io.sh
# Funciones compartidas de I/O, validación y utilidades para todos los generadores

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
      log "ERROR" "El nombre de la entidad no puede estar vacío"
      return 1
    fi
    if [[ ! "$entity" =~ ^[a-zA-Z][a-zA-Z0-9_-]*$ ]]; then
      log "ERROR" "El nombre de la entidad debe comenzar con una letra y contener solo letras, números, guiones y guiones bajos"
      return 1
    fi
    return 0
  }

  ensure_directory() {
    local dir_path="$1"
    if ! mkdir -p "$dir_path" 2>/dev/null; then
      log "ERROR" "No se pudo crear el directorio: $dir_path"
      return 1
    fi
  }

  confirm_overwrite() {
    local file_path="$1"
    local file_type="${2:-archivo}"
    local auto_confirm="${AUTO_CONFIRM:-false}"

    if [[ -e "$file_path" && "$auto_confirm" != "true" ]]; then
      printf "${YELLOW}⚠️  El %s %s ya existe. ¿Deseas sobrescribirlo? [s/N]: ${NC}" "$file_type" "$file_path"
      read -r confirm
      if [[ ! "$confirm" =~ ^[Ss]$ ]]; then
        log "INFO" "Omitido: $file_path"
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
        log "SUCCESS" "Generado: $file_path"
        return 0
      else
        log "ERROR" "No se pudo escribir el archivo: $file_path"
        return 1
      fi
    fi
    return 0
  }
fi
