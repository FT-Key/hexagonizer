#!/bin/bash
# generator/project/11-generate-base-middlewares.sh
# shellcheck disable=SC1091

set -e

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

# ========================
# LOGGING FUNCTION
# ========================
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

# ========================
# INITIALIZATION
# ========================
init_environment() {
  PROJECT_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"

  log "INFO" "Inicializando entorno para generar middlewares base"
  log "INFO" "Directorio raíz del proyecto: $PROJECT_ROOT"

  # Verificar si CREATE_MIDDLEWARES está habilitado
  if [ "$CREATE_MIDDLEWARES" != "true" ]; then
    log "WARN" "CREATE_MIDDLEWARES no está habilitado, saltando generación de middlewares"
    return 2 # Código especial para skip
  fi

  log "SUCCESS" "CREATE_MIDDLEWARES habilitado, continuando con la generación"
}

# ========================
# DIRECTORY CREATION
# ========================
create_directories() {
  local target_dir="src/interfaces/http/middlewares"

  log "INFO" "Creando directorio: $target_dir"

  if mkdir -p "$target_dir"; then
    log "SUCCESS" "Directorio creado correctamente: $target_dir"
  else
    log "ERROR" "Error al crear el directorio: $target_dir"
    return 1
  fi
}

# ========================
# UTILITY FUNCTIONS
# ========================
create_file_if_not_exists() {
  local filepath="$1"
  local content="$2"
  local filename
  filename=$(basename "$filepath")

  log "INFO" "Verificando archivo: $filepath"

  if [ -f "$filepath" ]; then
    log "WARN" "$filename ya existe, no se sobrescribirá"
    return 0
  else
    if echo "$content" >"$filepath"; then
      log "SUCCESS" "$filename creado correctamente"
      return 0
    else
      log "ERROR" "Error al crear $filename"
      return 1
    fi
  fi
}

# ========================
# MIDDLEWARE CONTENT GENERATORS
# ========================
generate_auth_middleware_content() {
  cat <<'EOF'
export function authMiddleware(req, res, next) {
  const authHeader = req.headers.authorization;

  if (!authHeader || !authHeader.startsWith('Bearer ')) {
    return res.status(401).json({ message: 'No autorizado: token requerido' });
  }

  const token = authHeader.split(' ')[1];

  try {
    // TODO: Verificá el token (con JWT u otro mecanismo)
    // const payload = jwt.verify(token, process.env.JWT_SECRET);
    // req.user = payload;

    next();
  } catch (error) {
    return res.status(401).json({ message: 'Token inválido o expirado' });
  }
}
EOF
}

generate_check_role_middleware_content() {
  cat <<'EOF'
export function checkRole(requiredRole) {
  return (req, res, next) => {
    const user = req.user;
    if (!user) return res.status(401).json({ message: 'No autorizado' });
    if (user.role !== requiredRole) {
      return res.status(403).json({ message: 'Acceso denegado' });
    }
    next();
  };
}

export function checkRoleOrOwner(requiredRole) {
  return (req, res, next) => {
    const user = req.user;
    if (!user) return res.status(401).json({ message: 'No autorizado' });
    if (user.role === requiredRole) return next();
    if (req.params.id && req.params.id === user.id) return next();
    return res.status(403).json({ message: 'Acceso denegado' });
  };
}
EOF
}

generate_error_handler_middleware_content() {
  cat <<'EOF'
export default function errorHandler(err, req, res, next) {
  console.error('❌ Error capturado:', err.stack || err.message);
  res.status(err.status || 500).json({
    error: {
      message: err.message || 'Error interno del servidor',
    },
  });
}
EOF
}

generate_rate_limiter_middleware_content() {
  cat <<'EOF'
import rateLimit from 'express-rate-limit';

export const rateLimiter = rateLimit({
  windowMs: 15 * 60 * 1000,
  max: 100,
  message: 'Demasiadas solicitudes desde esta IP, intentá más tarde',
  standardHeaders: true,
  legacyHeaders: false,
});
EOF
}

generate_request_logger_middleware_content() {
  cat <<'EOF'
export function requestLogger(req, res, next) {
  console.log(`📥 ${req.method} ${req.originalUrl}`);
  next();
}
EOF
}

generate_sanitize_middleware_content() {
  cat <<'EOF'
import xss from 'xss-clean';
import mongoSanitize from 'express-mongo-sanitize';

export const sanitizeMiddleware = [
  mongoSanitize(),
  xss(),
];
EOF
}

# ========================
# MIDDLEWARE CREATION FUNCTIONS
# ========================
create_auth_middleware() {
  local filepath="src/interfaces/http/middlewares/auth.middleware.js"
  local content
  content=$(generate_auth_middleware_content)
  create_file_if_not_exists "$filepath" "$content"
}

create_check_role_middleware() {
  local filepath="src/interfaces/http/middlewares/check-role.middleware.js"
  local content
  content=$(generate_check_role_middleware_content)
  create_file_if_not_exists "$filepath" "$content"
}

create_error_handler_middleware() {
  local filepath="src/interfaces/http/middlewares/error-handler.middleware.js"
  local content
  content=$(generate_error_handler_middleware_content)
  create_file_if_not_exists "$filepath" "$content"
}

create_rate_limiter_middleware() {
  local filepath="src/interfaces/http/middlewares/rate-limiter.middleware.js"
  local content
  content=$(generate_rate_limiter_middleware_content)
  create_file_if_not_exists "$filepath" "$content"
}

create_request_logger_middleware() {
  local filepath="src/interfaces/http/middlewares/request-logger.middleware.js"
  local content
  content=$(generate_request_logger_middleware_content)
  create_file_if_not_exists "$filepath" "$content"
}

create_sanitize_middleware() {
  local filepath="src/interfaces/http/middlewares/sanitize.middleware.js"
  local content
  content=$(generate_sanitize_middleware_content)
  create_file_if_not_exists "$filepath" "$content"
}

# ========================
# MIDDLEWARE ORCHESTRATION
# ========================
create_all_middlewares() {
  log "INFO" "Iniciando creación de todos los middlewares base"

  local failed=0

  # Crear cada middleware individualmente
  if ! create_auth_middleware; then
    ((failed++))
  fi

  if ! create_check_role_middleware; then
    ((failed++))
  fi

  if ! create_error_handler_middleware; then
    ((failed++))
  fi

  if ! create_rate_limiter_middleware; then
    ((failed++))
  fi

  if ! create_request_logger_middleware; then
    ((failed++))
  fi

  if ! create_sanitize_middleware; then
    ((failed++))
  fi

  if [ $failed -gt 0 ]; then
    log "ERROR" "$failed middlewares fallaron al crearse"
    return 1
  else
    log "SUCCESS" "Todos los middlewares base fueron procesados correctamente"
    return 0
  fi
}

# ========================
# QUERY MIDDLEWARES INTEGRATION
# ========================
generate_query_middlewares() {
  local query_script="$PROJECT_ROOT/generator/common/generate-query-middlewares.sh"

  log "INFO" "Ejecutando generación de middlewares de query"

  if [[ -f "$query_script" ]]; then
    log "INFO" "Ejecutando: $query_script"
    if bash "$query_script" "$@"; then
      log "SUCCESS" "Middlewares de query generados correctamente"
    else
      log "ERROR" "Error al generar middlewares de query"
      return 1
    fi
  else
    log "WARN" "Script de middlewares de query no encontrado: $query_script"
    log "WARN" "Continuando sin middlewares de query"
  fi
}

# ========================
# MAIN FUNCTION
# ========================
main() {
  log "INFO" "Iniciando proceso de generación de middlewares base"

  # Inicializar entorno
  local init_result
  init_environment
  init_result=$?

  if [ $init_result -eq 2 ]; then
    # Skip solicitado
    log "INFO" "Proceso saltado por configuración"
    exit 0
  elif [ $init_result -ne 0 ]; then
    log "ERROR" "Error en la inicialización del entorno"
    exit 1
  fi

  # Crear directorios
  if ! create_directories; then
    log "ERROR" "Error al crear directorios"
    exit 1
  fi

  # Crear todos los middlewares
  if ! create_all_middlewares; then
    log "ERROR" "Error al crear middlewares base"
    exit 1
  fi

  # Generar middlewares de query
  if ! generate_query_middlewares "$@"; then
    log "ERROR" "Error al generar middlewares de query"
    exit 1
  fi

  log "SUCCESS" "Proceso de generación de middlewares base completado exitosamente"
  log "SUCCESS" "Middlewares base (incluyendo filtros, orden, búsqueda, paginación) verificados o generados"
}

# ========================
# EXECUTION LOGIC
# ========================
# Si se llama directamente con bash
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
  main "$@"
fi

# Si se hace source y hay condiciones específicas
if [[ "${BASH_SOURCE[0]}" != "${0}" && (-n "${CREATE_MIDDLEWARES:-}" || $# -gt 0) ]]; then
  main "$@"
fi
