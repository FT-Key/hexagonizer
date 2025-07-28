#!/bin/bash
# generator/entity/11-generate-routes.sh
# shellcheck disable=SC2154
# 5. ROUTES Generator

# ========================
# COLORES PARA OUTPUT
# ========================
if [[ -z "${RED:-}" ]]; then
  readonly RED='\033[0;31m'
  readonly GREEN='\033[0;32m'
  readonly YELLOW='\033[1;33m'
  readonly BLUE='\033[0;34m'
  readonly NC='\033[0m' # No Color
fi

log() {
  local level="$1"
  shift
  local message="$*"
  local timestamp
  timestamp=$(date '+%Y-%m-%d %H:%M:%S')

  case "$level" in
  "INFO") printf "${BLUE}[INFO]${NC}    %s - %s\n" "$timestamp" "$message" ;;
  "SUCCESS") printf "${GREEN}[SUCCESS]${NC} %s - %s\n" "$timestamp" "$message" ;;
  "WARN") printf "${YELLOW}[WARN]${NC}    %s - %s\n" "$timestamp" "$message" ;;
  "ERROR") printf "${RED}[ERROR]${NC}   %s - %s\n" "$timestamp" "$message" >&2 ;;
  esac
}

main() {
  if [[ -z "${entity:-}" || -z "${EntityPascal:-}" ]]; then
    log "ERROR" "Las variables 'entity' y 'EntityPascal' deben estar definidas"
    echo "Uso: $0 <entity> <EntityPascal>"
    echo "Ejemplo: $0 user User"
    return 1
  fi

  generate_routes
}

generate_routes() {
  local routes_file="src/interfaces/http/$entity/${entity}.routes.js"

  mkdir -p "$(dirname "$routes_file")"
  log "INFO" "📁 Directorio asegurado para rutas: $(dirname "$routes_file")"

  if ! should_overwrite_file "$routes_file"; then
    log "WARN" "Rutas omitidas: $routes_file"
    return 0
  fi

  create_routes_content "$routes_file"
  log "SUCCESS" "Rutas generadas: $routes_file"
}

should_overwrite_file() {
  local file="$1"

  if [[ -f "$file" && "$AUTO_CONFIRM" != true ]]; then
    read -r -p "El archivo $file ya existe. ¿Deseas sobrescribirlo? [y/n]: " confirm
    [[ "$confirm" =~ ^[Yy]$ ]]
  else
    true
  fi
}

create_routes_content() {
  local routes_file="$1"

  cat <<EOF >"$routes_file"
import express from 'express';
import {
  create${EntityPascal}Controller,
  get${EntityPascal}Controller,
  update${EntityPascal}Controller,
  delete${EntityPascal}Controller,
  deactivate${EntityPascal}Controller,
  list${EntityPascal}sController,
} from './${entity}.controller.js';

const router = express.Router();

// CRUD Operations
router.post('/', create${EntityPascal}Controller);
router.get('/', list${EntityPascal}sController);
router.get('/:id', get${EntityPascal}Controller);
router.put('/:id', update${EntityPascal}Controller);
router.delete('/:id', delete${EntityPascal}Controller);

// Additional Operations
router.patch('/:id/deactivate', deactivate${EntityPascal}Controller);

export default router;
EOF
}

parse_arguments() {
  if [[ $# -ge 2 ]]; then
    entity="$1"
    EntityPascal="$2"
  fi
}

if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
  parse_arguments "$@"
  main "$@"
fi

if [[ -n "${entity:-}" && -n "${EntityPascal:-}" ]]; then
  main "$@"
fi
