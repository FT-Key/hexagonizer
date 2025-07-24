#!/bin/bash
# hexagonizer/project/05-create-index-and-server.sh
# shellcheck disable=SC1091

# Obtener ruta absoluta al root del CLI (asumiendo que estamos en hexagonizer/project)
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "$SCRIPT_DIR/../.." && pwd)"

# Importar confirm-action desde common
source "$PROJECT_ROOT/generator/common/confirm-action.sh"

write_file_with_confirm() {
  local filepath=$1
  local content=$2

  if [[ -f "$filepath" ]]; then
    if [[ "$AUTO_YES" == true ]]; then
      echo "⚠️  El archivo $filepath ya existe. Sobrescribiendo por opción -y."
      echo "$content" >"$filepath"
    else
      if confirm_action "⚠️  El archivo $filepath ya existe. ¿Desea sobrescribirlo? (y/n): "; then
        echo "$content" >"$filepath"
      else
        echo "❌ No se sobrescribió $filepath"
        return 1
      fi
    fi
  else
    echo "$content" >"$filepath"
  fi
}

mkdir -p src/public

# 1) Generar server.js con serve estático y ruta /
write_file_with_confirm "src/config/server.js" "$(
  cat <<'EOF'
import express from 'express';
import path from 'path';
import { fileURLToPath } from 'url';

// Definir __dirname en ESModules
const __filename = fileURLToPath(import.meta.url);
const __dirname = path.dirname(__filename);

export class Server {
  constructor({ routes = [], middlewares = [] } = {}) {
    this.app = express();
    this.routes = routes;
    this.middlewares = middlewares;
  }

  setupMiddlewares() {
    this.app.use(express.json());

    // Servir archivos estáticos desde la carpeta 'src/public'
    this.app.use(express.static(path.resolve(__dirname, '../public')));

    this.middlewares.forEach((mw) => this.app.use(mw));
  }

  setupRoutes() {
    this.routes.forEach(({ path: routePath, handler }) => {
      this.app.use(routePath, handler);
    });

    // Ruta raíz para servir index.html explícitamente
    this.app.get('/', (req, res) => {
      res.sendFile(path.resolve(__dirname, '../public/index.html'));
    });
  }

  start(port = 3000) {
    this.setupMiddlewares();
    this.setupRoutes();

    this.app.listen(port, () => {
      console.log(`🚀 Servidor iniciado en http://localhost:${port}`);
    });
  }

  getApp() {
    return this.app;
  }
}
EOF
)"

# 2) Generar index.js
write_file_with_confirm "src/index.js" "$(
  cat <<'EOF'
import { Server } from './config/server.js';

import healthRoutes from './interfaces/http/health/health.routes.js';
import publicRoutes from './interfaces/http/public/public.routes.js';

// import entityRoutes from './interfaces/http/entity/entity.routes.js';

import { wrapRouterWithFlexibleMiddlewares } from './utils/wrap-router-with-flexible-middlewares.js';
// import { entityQueryConfig } from './interfaces/http/entity/query-entity-config.js';

const excludePathsByMiddleware = {
  // Por ahora sin exclusiones específicas
};

const routeMiddlewares = {};

// Middlewares globales comunes (como helmet, cors, etc) pueden ir acá
const globalMiddlewares = [];

// Ejemplo de cómo inyectar middlewares de búsqueda en /entity
// const entityRouterWithMiddlewares = wrapRouterWithFlexibleMiddlewares(entityRoutes, {
//   globalMiddlewares: createQueryMiddlewares(entityQueryConfig),
//   excludePathsByMiddleware,
//   routeMiddlewares,
// });

const healthRouter = wrapRouterWithFlexibleMiddlewares(healthRoutes, {
  globalMiddlewares,
  excludePathsByMiddleware,
  routeMiddlewares,
});

const publicRouter = wrapRouterWithFlexibleMiddlewares(publicRoutes, {
  globalMiddlewares,
  excludePathsByMiddleware,
  routeMiddlewares,
});

const server = new Server({
  middlewares: [],
  routes: [
    { path: '/health', handler: healthRouter },
    { path: '/public', handler: publicRouter },
    // { path: '/entity', handler: entityRouterWithMiddlewares },
  ],
});

server.start(process.env.PORT || 3000);
EOF
)"

# 3) Generar index.html completo en src/public
write_file_with_confirm "src/public/index.html" "$(
  cat <<'EOF'
<!DOCTYPE html>
<html lang="es">

<head>
  <meta charset="UTF-8">
  <meta name="viewport" content="width=device-width, initial-scale=1.0">
  <title>Hexagonizer</title>
  <style>
    * {
      margin: 0;
      padding: 0;
      box-sizing: border-box;
    }

    body {
      background: #0a0a0a;
      font-family: 'Arial', sans-serif;
      overflow: hidden;
      height: 100vh;
    }

    /* Navbar */
    .navbar {
      position: fixed;
      top: 0;
      left: 0;
      right: 0;
      height: 70px;
      background: rgba(0, 0, 0, 0.9);
      backdrop-filter: blur(10px);
      border-bottom: 1px solid rgba(0, 255, 157, 0.2);
      display: flex;
      justify-content: space-between;
      align-items: center;
      padding: 0 2rem;
      z-index: 100;
    }

    .logo {
      font-size: 1.5rem;
      font-weight: bold;
      color: #00ff9d;
      text-shadow: 0 0 10px #00ff9d;
    }

    .nav-links {
      display: flex;
      gap: 2rem;
    }

    .nav-links a {
      color: #fff;
      text-decoration: none;
      padding: 0.5rem 1rem;
      border: 1px solid rgba(0, 255, 157, 0.3);
      border-radius: 4px;
      transition: all 0.3s ease;
      font-size: 0.9rem;
    }

    .nav-links a:hover {
      color: #00ff9d;
      border-color: #00ff9d;
      box-shadow: 0 0 10px rgba(0, 255, 157, 0.3);
    }

    /* Container principal */
    .container {
      height: 100vh;
      display: flex;
      justify-content: center;
      align-items: center;
      background: radial-gradient(ellipse at center, rgba(0, 255, 157, 0.1) 0%, rgba(0, 0, 0, 1) 70%);
    }

    /* Anillo Hexagonal 3D */
    .hexagon-container {
      perspective: 1000px;
      perspective-origin: center center;
    }

    .hexagon {
      width: 200px;
      height: 200px;
      position: relative;
      transform-style: preserve-3d;
      animation: rotate 15s linear infinite alternate;
    }
    
    .hexagon:hover .segment-face {
      box-shadow:
        0 0 40px rgba(0, 255, 157, 0.6),
        inset 0 0 25px rgba(0, 255, 157, 0.2);
    }

    .hexagon-segment {
      position: absolute;
      width: 100px;
      height: 30px;
      transform-style: preserve-3d;
      left: 50%;
      top: 50%;
      margin-left: -50px;
      margin-top: -15px;
    }

    .segment-face {
      position: absolute;
      background: linear-gradient(45deg,
          rgba(0, 255, 157, 1) 0%,
          rgba(0, 255, 255, 1) 50%,
          rgba(0, 255, 157, 1) 100%);
      border: 1px solid #00ff9d;
      box-shadow:
        0 0 15px rgba(0, 255, 157, 0.6),
        inset 0 0 10px rgba(0, 255, 157, 0.2);
      transition: all 1s ease;
    }

    .face-front,
    .face-back {
      width: 100px;
      height: 30px;
    }

    .face-left,
    .face-right {
      width: 20px;
      height: 30px;
    }

    .face-top,
    .face-bottom {
      width: 100px;
      height: 20px;
    }

    .face-front {
      transform: translateZ(10px);
    }

    .face-back {
      transform: translateZ(-10px);
    }

    .face-left {
      transform: rotateY(-90deg) translateZ(10px);
    }

    .face-right {
      transform: rotateY(90deg) translateZ(90px);
    }

    .face-top {
      transform: rotateX(90deg) translateZ(15px);
    }

    .face-bottom {
      transform: rotateX(-90deg) translateZ(15px);
    }

    .segment-1 {
      transform: translateZ(80px) rotateY(0deg);
    }

    .segment-2 {
      transform: rotateY(60deg) translateZ(80px);
    }

    .segment-3 {
      transform: rotateY(120deg) translateZ(80px);
    }

    .segment-4 {
      transform: rotateY(180deg) translateZ(80px);
    }

    .segment-5 {
      transform: rotateY(240deg) translateZ(80px);
    }

    .segment-6 {
      transform: rotateY(300deg) translateZ(80px);
    }

    @keyframes rotate {
      0% {
        transform: rotateY(90deg) rotateX(100deg);
      }

      100% {
        transform: rotateY(450deg) rotateX(100deg);
      }
    }

    .glow-ring {
      position: absolute;
      top: 50%;
      left: 50%;
      transform: translate(-50%, -50%);
      width: 300px;
      height: 300px;
      border: 1px solid rgba(0, 255, 157, 0.3);
      border-radius: 50%;
      animation: pulse 3s ease-in-out infinite;
    }

    .glow-ring::before {
      content: '';
      position: absolute;
      top: -2px;
      left: -2px;
      right: -2px;
      bottom: -2px;
      border: 1px solid rgba(0, 255, 255, 0.2);
      border-radius: 50%;
      animation: pulse 3s ease-in-out infinite reverse;
    }

    @keyframes pulse {
      0%, 100% {
        transform: translate(-50%, -50%) scale(1);
        opacity: 0.5;
      }
      50% {
        transform: translate(-50%, -50%) scale(1.1);
        opacity: 0.8;
      }
    }

    .particles {
      position: absolute;
      width: 100%;
      height: 100%;
      overflow: hidden;
    }

    .particle {
      position: absolute;
      width: 2px;
      height: 2px;
      background: #00ff9d;
      border-radius: 50%;
      animation: float 6s ease-in-out infinite;
      opacity: 0.7;
    }

    @keyframes float {
      0%, 100% {
        transform: translateY(0px) rotate(0deg);
      }
      50% {
        transform: translateY(-20px) rotate(180deg);
      }
    }

    @media (max-width: 768px) {
      .navbar {
        padding: 0 1rem;
      }

      .logo {
        font-size: 1.2rem;
      }

      .nav-links {
        gap: 1rem;
      }

      .nav-links a {
        padding: 0.4rem 0.8rem;
        font-size: 0.8rem;
      }

      .hexagon-segment {
        width: 120px;
        height: 120px;
      }

      .segment-face.face-front,
      .segment-face.face-back {
        width: 75px;
        height: 22px;
      }

      .segment-face.face-left,
      .segment-face.face-right {
        width: 15px;
        height: 22px;
      }

      .segment-face.face-top,
      .segment-face.face-bottom {
        width: 75px;
        height: 15px;
      }

      .glow-ring {
        width: 250px;
        height: 250px;
      }
    }
  </style>
</head>

<body>
  <nav class="navbar">
    <div class="logo">HEXAGONIZER</div>
    <div class="nav-links">
      <a href="/health">Health</a>
      <a href="/public/info">Public</a>
    </div>
  </nav>

  <div class="container">
    <div class="particles" id="particles"></div>

    <div class="hexagon-container">
      <div class="glow-ring"></div>
      <div class="hexagon">
        <div class="hexagon-segment segment-1">
          <div class="segment-face face-front"></div>
          <div class="segment-face face-back"></div>
          <div class="segment-face face-left"></div>
          <div class="segment-face face-right"></div>
          <div class="segment-face face-top"></div>
          <div class="segment-face face-bottom"></div>
        </div>
        <div class="hexagon-segment segment-2">
          <div class="segment-face face-front"></div>
          <div class="segment-face face-back"></div>
          <div class="segment-face face-left"></div>
          <div class="segment-face face-right"></div>
          <div class="segment-face face-top"></div>
          <div class="segment-face face-bottom"></div>
        </div>
        <div class="hexagon-segment segment-3">
          <div class="segment-face face-front"></div>
          <div class="segment-face face-back"></div>
          <div class="segment-face face-left"></div>
          <div class="segment-face face-right"></div>
          <div class="segment-face face-top"></div>
          <div class="segment-face face-bottom"></div>
        </div>
        <div class="hexagon-segment segment-4">
          <div class="segment-face face-front"></div>
          <div class="segment-face face-back"></div>
          <div class="segment-face face-left"></div>
          <div class="segment-face face-right"></div>
          <div class="segment-face face-top"></div>
          <div class="segment-face face-bottom"></div>
        </div>
        <div class="hexagon-segment segment-5">
          <div class="segment-face face-front"></div>
          <div class="segment-face face-back"></div>
          <div class="segment-face face-left"></div>
          <div class="segment-face face-right"></div>
          <div class="segment-face face-top"></div>
          <div class="segment-face face-bottom"></div>
        </div>
        <div class="hexagon-segment segment-6">
          <div class="segment-face face-front"></div>
          <div class="segment-face face-back"></div>
          <div class="segment-face face-left"></div>
          <div class="segment-face face-right"></div>
          <div class="segment-face face-top"></div>
          <div class="segment-face face-bottom"></div>
        </div>
      </div>
    </div>
  </div>

  <script>
    function createParticles() {
      const particlesContainer = document.getElementById('particles');
      const particleCount = 30;

      for (let i = 0; i < particleCount; i++) {
        const particle = document.createElement('div');
        particle.className = 'particle';
        particle.style.left = Math.random() * 100 + '%';
        particle.style.top = Math.random() * 100 + '%';
        particle.style.animationDelay = Math.random() * 6 + 's';
        particle.style.animationDuration = (3 + Math.random() * 4) + 's';
        particlesContainer.appendChild(particle);
      }
    }

    document.addEventListener('DOMContentLoaded', createParticles);
  </script>
</body>

</html>
EOF
)"

# 2) Generar health.routes.js
write_file_with_confirm "src/interfaces/http/health/health.routes.js" "$(
  cat <<'EOF'
import express from 'express';

const router = express.Router();

router.get('/', (req, res) => {
  res.json({ status: 'ok', timestamp: Date.now() });
});

export default router;
EOF
)"

# 2) Generar public.routes.js
write_file_with_confirm "src/interfaces/http/public/public.routes.js" "$(
  cat <<'EOF'
import express from 'express';

const router = express.Router();

router.get('/info', (req, res) => {
  res.json({ app: 'Backend Template', version: '1.0.0', description: 'Información pública' });
});

export default router;
EOF
)"

# 2) Generar wrap-router-with-flexible-middlewares.js
write_file_with_confirm "src/utils/wrap-router-with-flexible-middlewares.js" "$(
  cat <<'EOF'
import express from 'express';
import { match } from 'path-to-regexp';

export function wrapRouterWithFlexibleMiddlewares(router, options = {}) {
  const {
    globalMiddlewares = [],
    excludePathsByMiddleware = {},
    routeMiddlewares = {},
  } = options;

  const wrapped = express.Router();

  globalMiddlewares.forEach((mw) => {
    const mwName = mw.name || 'anonymous';

    wrapped.use((req, res, next) => {
      const excludes = excludePathsByMiddleware[mwName] || [];
      if (excludes.some(path => match(path, { decode: decodeURIComponent })(req.path))) {
        return next();
      }
      return mw(req, res, next);
    });
  });

  wrapped.use((req, res, next) => {
    for (const pattern in routeMiddlewares) {
      const isMatch = match(pattern, { decode: decodeURIComponent })(req.path);
      if (isMatch) {
        const mws = routeMiddlewares[pattern];
        if (!mws.length) return next();

        let i = 0;
        function run(i) {
          if (i >= mws.length) return next();
          mws[i](req, res, () => run(i + 1));
        }
        return run(0);
      }
    }
    return next();
  });

  wrapped.use(router);

  return wrapped;
}
EOF
)"

echo "✅ server.js, index.js, index.html, health.routes.js, publuc.routes.js y wrap-router-with-flexible-middlewares.js generados correctamente."
