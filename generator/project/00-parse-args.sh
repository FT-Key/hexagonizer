#!/bin/bash
# 00-parse-args.sh

# Procesar argumentos para detectar -y / --yes
AUTO_YES=false
for arg in "${INIT_ARGS[@]}"; do
  if [[ "$arg" == "-y" || "$arg" == "--yes" ]]; then
    AUTO_YES=true
    break
  fi
done

export AUTO_YES
