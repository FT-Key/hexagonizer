#!/bin/bash
# shellcheck disable=SC1091
# shellcheck disable=SC2034

set -e

# Obtener la ruta absoluta del directorio del script
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"

# Guardar args para pasar a módulos
INIT_ARGS=("$@")

# Ejecutar primer módulo para parsear args
bash "$PROJECT_ROOT/generator/project/00-parse-args.sh"

# Importar función confirm_action
source "$PROJECT_ROOT/generator/common/confirm-action.sh"

# Preguntar si se desean crear middlewares base
if [ "$AUTO_YES" = true ]; then
  CREATE_MIDDLEWARES=true
else
  read -r -p "¿Deseas agregar middlewares base (auth, role, error, etc)? (y/n): " middleware_response
  middleware_response=${middleware_response,,}
  CREATE_MIDDLEWARES=false
  [[ "$middleware_response" =~ ^(y|yes|s|si)$ ]] && CREATE_MIDDLEWARES=true
fi

export CREATE_MIDDLEWARES

# Ejecutar el resto de módulos (excepto 00-parse-args.sh)
for script in "$PROJECT_ROOT/generator/project"/[0-9][0-9]-*.sh; do
  if [[ "$script" != *"00-parse-args.sh" ]]; then
    echo "▶ Ejecutando $script"
    bash "$script"
  fi
done

echo "✅ Proyecto generado con éxito. ¡Listo para comenzar!"
