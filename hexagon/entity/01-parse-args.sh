#!/bin/bash
# shellcheck disable=SC2034
AUTO_CONFIRM=false
USE_JSON=false

for arg in "$@"; do
  case $arg in
  -y) AUTO_CONFIRM=true ;;
  --json) USE_JSON=true ;;
  esac
done
