#!/bin/bash
# generator/project/11-generate-base-middlewares.sh
# shellcheck disable=SC1091

set -e

source "$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)/../common/logging.sh"

# ========================
# INITIALIZATION
# ========================
init_environment() {
  PROJECT_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"

  if [ "$CREATE_MIDDLEWARES" != "true" ]; then
    log "WARN" "CREATE_MIDDLEWARES not enabled, skipping middleware generation"
    return 2
  fi
}

# ========================
# DIRECTORY CREATION
# ========================
create_directories() {
  mkdir -p src/interfaces/http/middlewares
}

# ========================
# UTILITY FUNCTIONS
# ========================
write_file() {
  local filepath="$1"
  local content="$2"
  [ -f "$filepath" ] && return 0
  echo "$content" >"$filepath" || { log "ERROR" "Error writing $(basename "$filepath")"; return 1; }
}

# ========================
# MAIN FUNCTION
# ========================
main() {
  init_environment
  local rc=$?
  [ $rc -eq 2 ] && exit 0
  [ $rc -ne 0 ] && exit 1

  create_directories

  write_file "src/interfaces/http/middlewares/auth.middleware.js" \
'export function authMiddleware(req, res, next) {
  const authHeader = req.headers.authorization;
  if (!authHeader || !authHeader.startsWith("Bearer ")) {
    return res.status(401).json({ message: "No autorizado: token requerido" });
  }
  const token = authHeader.split(" ")[1];
  try {
    next();
  } catch (error) {
    return res.status(401).json({ message: "Invalid or expired token" });
  }
}'

  write_file "src/interfaces/http/middlewares/check-role.middleware.js" \
'export function checkRole(requiredRole) {
  return (req, res, next) => {
    const user = req.user;
    if (!user) return res.status(401).json({ message: "No autorizado" });
    if (user.role !== requiredRole) return res.status(403).json({ message: "Acceso denegado" });
    next();
  };
}

export function checkRoleOrOwner(requiredRole) {
  return (req, res, next) => {
    const user = req.user;
    if (!user) return res.status(401).json({ message: "No autorizado" });
    if (user.role === requiredRole) return next();
    if (req.params.id && req.params.id === user.id) return next();
    return res.status(403).json({ message: "Acceso denegado" });
  };
}'

  write_file "src/interfaces/http/middlewares/error-handler.middleware.js" \
'export default function errorHandler(err, req, res, next) {
  console.error("Error capturado:", err.stack || err.message);
  res.status(err.status || 500).json({
    error: { message: err.message || "Error interno del servidor" },
  });
}'

  write_file "src/interfaces/http/middlewares/rate-limiter.middleware.js" \
'import rateLimit from "express-rate-limit";

export const rateLimiter = rateLimit({
  windowMs: 15 * 60 * 1000,
  max: 100,
  message: "Too many requests from this IP, try again later",
  standardHeaders: true,
  legacyHeaders: false,
});'

  write_file "src/interfaces/http/middlewares/request-logger.middleware.js" \
'export function requestLogger(req, res, next) {
  console.log(req.method, req.originalUrl);
  next();
}'

  write_file "src/interfaces/http/middlewares/sanitize.middleware.js" \
'import xss from "xss-clean";
import mongoSanitize from "express-mongo-sanitize";

export const sanitizeMiddleware = [
  mongoSanitize(),
  xss(),
];'

  log "SUCCESS" "Middlewares base creados"

  local query_script="$PROJECT_ROOT/generator/common/generate-query-middlewares.sh"
  if [[ -f "$query_script" ]]; then
    bash "$query_script" "$@" || { log "ERROR" "Error generando middlewares de query"; return 1; }
  fi
}

# ========================
# EXECUTION LOGIC
# ========================
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
  main "$@"
fi
