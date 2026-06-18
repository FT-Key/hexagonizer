#!/bin/bash
# shellcheck disable=SC2034
AUTO_CONFIRM=${AUTO_CONFIRM:-false}
USE_JSON=false
ENTITY_NAME=""

for arg in "$@"; do
  case $arg in
  -y) AUTO_CONFIRM=true ;;
  --json) USE_JSON=true ;;
  -*)
    # ignore other flags
    ;;
  *)
    # first positional argument is the entity name
    if [[ -z "$ENTITY_NAME" ]]; then
      ENTITY_NAME="$arg"
    fi
    ;;
  esac
done

export AUTO_CONFIRM ENTITY_NAME
