#!/bin/bash
# hexagonizer/entity/13-generate-query-middlewares-and-utils.sh
# shellcheck disable=SC1091,SC2154
set -e

# Función principal
main() {
  # Validar que las variables necesarias estén definidas
  validate_required_variables

  # Inicializar variables del proyecto
  init_project_variables

  # Generar middlewares y utils de query
  generate_query_components
}

# Función para validar variables requeridas
validate_required_variables() {
  if [[ -z "${entity:-}" ]]; then
    echo "❌ Error: La variable 'entity' es requerida"
    echo "Uso: $0 <entity>"
    echo "Ejemplo: $0 user"
    return 1
  fi
}

# Función para inicializar variables del proyecto
init_project_variables() {
  # Obtener ruta raíz del proyecto (asumiendo que este archivo está en hexagonizer/entity/)
  if [[ -z "${PROJECT_ROOT:-}" ]]; then
    PROJECT_ROOT="$(cd "$(dirname "$(dirname "$(dirname "${BASH_SOURCE[0]}")")")" && pwd)"
  fi

  readonly COMMON_DIR="$PROJECT_ROOT/generator/common"
  readonly MIDDLEWARES_SCRIPT="$COMMON_DIR/generate-query-middlewares.sh"
  readonly UTILS_SCRIPT="$COMMON_DIR/generate-query-utils.sh"
}

# Función para validar que los scripts comunes existan
validate_common_scripts() {
  local missing_scripts=()

  if [[ ! -f "$MIDDLEWARES_SCRIPT" ]]; then
    missing_scripts+=("$MIDDLEWARES_SCRIPT")
  fi

  if [[ ! -f "$UTILS_SCRIPT" ]]; then
    missing_scripts+=("$UTILS_SCRIPT")
  fi

  if [[ ${#missing_scripts[@]} -gt 0 ]]; then
    echo "❌ Error: No se encontraron los siguientes scripts:"
    printf "  - %s\n" "${missing_scripts[@]}"
    return 1
  fi
}

# Función para generar componentes de query
generate_query_components() {
  echo "🔧 Generando middlewares y utils de query para la entidad: $entity"

  # Validar que los scripts comunes existan
  validate_common_scripts

  # Incluir y ejecutar scripts desde common
  echo "📦 Cargando script de middlewares..."
  source "$MIDDLEWARES_SCRIPT" || {
    echo "❌ Error al cargar el script de middlewares"
    return 1
  }

  echo "📦 Cargando script de utils..."
  source "$UTILS_SCRIPT" || {
    echo "❌ Error al cargar el script de utils"
    return 1
  }

  echo "✅ Query middlewares y utils generados correctamente"
}

# Función para mostrar información de debug
show_debug_info() {
  if [[ "${DEBUG:-}" == "true" ]]; then
    cat <<EOF
🐛 Información de debug:
  - Entity: ${entity:-"No definida"}
  - PROJECT_ROOT: ${PROJECT_ROOT:-"No definida"}
  - MIDDLEWARES_SCRIPT: ${MIDDLEWARES_SCRIPT:-"No definida"}
  - UTILS_SCRIPT: ${UTILS_SCRIPT:-"No definida"}
EOF
  fi
}

# Manejo de argumentos si se ejecuta directamente
parse_arguments() {
  while [[ $# -gt 0 ]]; do
    case $1 in
    --debug)
      DEBUG=true
      shift
      ;;
    -h | --help)
      show_help
      exit 0
      ;;
    *)
      if [[ -z "${entity:-}" ]]; then
        entity="$1"
      fi
      shift
      ;;
    esac
  done
}

# Función de ayuda
show_help() {
  cat <<EOF
Uso: $0 [OPCIONES] <entity>

Genera middlewares y utils de query para una entidad específica.

Argumentos:
  entity          Nombre de la entidad (ej: user, product)

Opciones:
  --debug         Mostrar información de debug
  -h, --help      Mostrar esta ayuda

Variables de entorno:
  PROJECT_ROOT    Ruta raíz del proyecto (se detecta automáticamente)

Ejemplo:
  $0 user
  $0 --debug product

EOF
}

# Ejecutar si se llama directamente
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
  parse_arguments "$@"
  show_debug_info
  main "$@"
fi

# Llamada implícita si fue sourced desde otro script
if [[ -n "${entity:-}" ]]; then
  main "$@"
fi
