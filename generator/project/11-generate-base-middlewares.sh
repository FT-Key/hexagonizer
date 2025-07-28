#!/bin/bash
# generator/project/10-generate-base-middlewares.sh
# shellcheck disable=SC1091

if [ "$CREATE_MIDDLEWARES" != "true" ]; then
  echo "⏩ Skipping base middlewares..."
  exit 0
fi

mkdir -p src/interfaces/http/middlewares

create_file_if_not_exists() {
  local filepath=$1
  local content=$2

  if [ -f "$filepath" ]; then
    echo "⚠️  $filepath ya existe, no se sobrescribirá."
  else
    echo "$content" >"$filepath"
    echo "✅ $filepath creado."
  fi
}

# === Base Middlewares ===

create_file_if_not_exists src/interfaces/http/middlewares/auth.middleware.js "$(
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
)"

create_file_if_not_exists src/interfaces/http/middlewares/check-role.middleware.js "$(
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
)"

create_file_if_not_exists src/interfaces/http/middlewares/error-handler.middleware.js "$(
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
)"

create_file_if_not_exists src/interfaces/http/middlewares/rate-limiter.middleware.js "$(
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
)"

create_file_if_not_exists src/interfaces/http/middlewares/request-logger.middleware.js "$(
  cat <<'EOF'
export function requestLogger(req, res, next) {
  console.log(`📥 ${req.method} ${req.originalUrl}`);
  next();
}
EOF
)"

create_file_if_not_exists src/interfaces/http/middlewares/sanitize.middleware.js "$(
  cat <<'EOF'
import xss from 'xss-clean';
import mongoSanitize from 'express-mongo-sanitize';

export const sanitizeMiddleware = [
  mongoSanitize(),
  xss(),
];
EOF
)"

# ✅ Reutilizar generación de middlewares de query
# Desde generator/project/06-generate-base-middlewares.sh
PROJECT_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"

bash "$PROJECT_ROOT/generator/common/generate-query-middlewares.sh" "$@"

echo "✅ Middlewares base (incluyendo filtros, orden, búsqueda, paginación) verificados o generados."
