#!/bin/bash
# generator/entity/10-generate-controller.sh
# shellcheck disable=SC2154
# 4. CONTROLLER Generator

# ===================================
# Colores para output
# ===================================
if [[ -z "${RED:-}" ]]; then
  readonly RED='\033[0;31m'
  readonly GREEN='\033[0;32m'
  readonly YELLOW='\033[1;33m'
  readonly BLUE='\033[0;34m'
  readonly NC='\033[0m' # No Color
fi

# ===================================
# Logging
# ===================================
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

  generate_controller
}

generate_controller() {
  local controller_file="src/interfaces/http/$entity/${entity}.controller.js"

  mkdir -p "$(dirname "$controller_file")"
  log "INFO" "📁 Directorio asegurado para controlador: $(dirname "$controller_file")"

  if [[ -f "$controller_file" && "$AUTO_CONFIRM" != true ]]; then
    read -r -p "El archivo $controller_file ya existe. ¿Deseas sobrescribirlo? [y/n]: " confirm
    if [[ ! "$confirm" =~ ^[Yy]$ ]]; then
      log "WARN" "Controlador omitido: $controller_file"
      return 0
    fi
  fi

  create_controller_content "$controller_file"
  log "SUCCESS" "Controlador generado: $controller_file"
}

create_controller_content() {
  local controller_file="$1"

  cat <<EOF >"$controller_file"
import { InMemory${EntityPascal}Repository } from '../../../infrastructure/$entity/in-memory-$entity-repository.js';

import { Create${EntityPascal} } from '../../../application/$entity/use-cases/create-$entity.js';
import { Get${EntityPascal} } from '../../../application/$entity/use-cases/get-$entity.js';
import { Update${EntityPascal} } from '../../../application/$entity/use-cases/update-$entity.js';
import { Delete${EntityPascal} } from '../../../application/$entity/use-cases/delete-$entity.js';
import { Deactivate${EntityPascal} } from '../../../application/$entity/use-cases/deactivate-$entity.js';
import { List${EntityPascal}s } from '../../../application/$entity/use-cases/list-$entity.js';

const repository = new InMemory${EntityPascal}Repository();

export const create${EntityPascal}Controller = async (req, res) => {
  const useCase = new Create${EntityPascal}(repository);
  const item = await useCase.execute(req.body);
  res.status(201).json(item);
};

export const get${EntityPascal}Controller = async (req, res) => {
  const useCase = new Get${EntityPascal}(repository);
  const item = await useCase.execute(req.params.id);
  if (!item) return res.status(404).json({ error: '${EntityPascal} not found' });
  res.json(item);
};

export const update${EntityPascal}Controller = async (req, res) => {
  const useCase = new Update${EntityPascal}(repository);
  const item = await useCase.execute(req.params.id, req.body);
  if (!item) return res.status(404).json({ error: '${EntityPascal} not found' });
  res.json(item);
};

export const delete${EntityPascal}Controller = async (req, res) => {
  const useCase = new Delete${EntityPascal}(repository);
  const success = await useCase.execute(req.params.id);
  res.status(success ? 204 : 404).send();
};

export const deactivate${EntityPascal}Controller = async (req, res) => {
  const useCase = new Deactivate${EntityPascal}(repository);
  const item = await useCase.execute(req.params.id);
  if (!item) return res.status(404).json({ error: '${EntityPascal} not found' });
  res.json(item);
};

export const list${EntityPascal}sController = async (req, res) => {
  try {
    const useCase = new List${EntityPascal}s(repository);
    const { filters, search, pagination, sort } = req;

    const { data, meta } = await useCase.execute({
      filters,
      search,
      pagination,
      sort,
    });

    res.status(200).json({ data, meta });
  } catch (error) {
    res.status(500).json({ error: error.message });
  }
};
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
