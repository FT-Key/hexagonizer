#!/bin/bash
confirm_action() {
  local prompt="$1"
  local result
  if $AUTO_CONFIRM; then
    result="y"
  else
    read -r -p "$prompt [y/n] " result
  fi
  [[ "$result" == "y" ]]
}