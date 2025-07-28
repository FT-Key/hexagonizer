#!/bin/bash
# generator/entity/05-generate-factory.sh
# shellcheck disable=SC2154
set -e

# ==========================================
# COLORES Y LOGGING (locales al archivo)
# ==========================================
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
  "INFO") printf "${BLUE}[INFO]${NC} %s: %s\n" "$timestamp" "$message" ;;
  "WARN") printf "${YELLOW}[WARN]${NC} %s: %s\n" "$timestamp" "$message" ;;
  "ERROR") printf "${RED}[ERROR]${NC} %s: %s\n" "$timestamp" "$message" >&2 ;;
  "SUCCESS") printf "${GREEN}[SUCCESS]${NC} %s: %s\n" "$timestamp" "$message" ;;
  esac
}

# ==========================================
# GENERACIÓN DE FACTORY
# ==========================================

factory_file="src/domain/$entity/${entity}-factory.js"

confirm_file_overwrite() {
  if [[ -f "$factory_file" && "$AUTO_CONFIRM" != true ]]; then
    printf "${YELLOW}⚠️  El archivo %s ya existe. ¿Desea sobrescribirlo? [s/N]: ${NC}" "$factory_file"
    read -r confirm
    if [[ ! "$confirm" =~ ^[Ss]$ ]]; then
      log "INFO" "⏭️  Fábrica omitida: $factory_file"
      exit 0
    fi
  fi
}

write_factory_file() {
  log "INFO" "Generando archivo de fábrica para $entity..."
  cat >"$factory_file" <<EOF
import { $EntityPascal } from './$entity.js';
import { validate${EntityPascal} } from './validate-$entity.js';

export class ${EntityPascal}Factory {
  /**
   * Crea una instancia de $EntityPascal validando los datos.
   * @param {Object} data - Datos para crear la instancia
   * @returns {$EntityPascal} Nueva instancia validada
   * @throws {Error} Si los datos no son válidos
   */
  static create(data) {
    validate${EntityPascal}(data);
    return new $EntityPascal(data);
  }

  /**
   * Crea múltiples instancias de $EntityPascal.
   * @param {Array<Object>} dataArray - Array de datos para crear instancias
   * @returns {Array<$EntityPascal>} Array de instancias validadas
   * @throws {Error} Si algún dato no es válido
   */
  static createMany(dataArray) {
    if (!Array.isArray(dataArray)) {
      throw new Error('dataArray must be an array');
    }
    return dataArray.map(data => this.create(data));
  }

  /**
   * Crea una instancia con valores por defecto.
   * @param {Object} overrides - Valores que sobrescribir los defaults
   * @returns {$EntityPascal} Nueva instancia con defaults
   */
  static createDefault(overrides = {}) {
    const defaultData = {
      id: \`\${Date.now()}-\${Math.random().toString(36).substr(2, 9)}\`,
      active: true,
      createdAt: new Date(),
      updatedAt: new Date(),
      deletedAt: null,
      ownedBy: null,
      ...overrides
    };
    return this.create(defaultData);
  }
}
EOF
}

# ==========================================
# EJECUCIÓN PRINCIPAL
# ==========================================

log "INFO" "=== GENERADOR DE FACTORY ==="
log "INFO" "Entidad: $entity ($EntityPascal)"
log "INFO" "Auto-confirmación: ${AUTO_CONFIRM:-false}"
echo ""

confirm_file_overwrite
write_factory_file
log "SUCCESS" "✅ Fábrica generada: $factory_file"
