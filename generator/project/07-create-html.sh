#!/bin/bash
# generator/project/07-create-html.sh

# ========================
# CONFIGURACIÓN INICIAL
# ========================
set -e
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "$SCRIPT_DIR/../.." && pwd)"

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
# DEPENDENCIAS
# ========================
source "$PROJECT_ROOT/generator/common/confirm-action.sh"

# ========================
# FUNCIONES PRINCIPALES
# ========================
create_public_directory() {
  log "INFO" "Verificando/creando directorio src/public"

  if mkdir -p src/public; then
    log "SUCCESS" "Directorio src/public está disponible"
    return 0
  else
    log "ERROR" "Error al crear el directorio src/public"
    return 1
  fi
}

create_html_file() {
  log "INFO" "Iniciando creación del archivo index.html"

  local html_content
  html_content="$(
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

      0%,
      100% {
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

      0%,
      100% {
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

      .hexagon {
        transform: scale(0.6);
        width: 160px;
        height: 160px;
      }

      .hexagon-segment {
        width: 80px;
        height: 24px;
        margin-left: -40px;
        margin-top: -12px;
      }

      .segment-face.face-front,
      .segment-face.face-back {
        width: 80px;
        height: 24px;
      }

      .segment-face.face-left,
      .segment-face.face-right {
        width: 16px;
        height: 24px;
      }

      .segment-face.face-right {
        display: none;
      }

      .segment-face.face-top,
      .segment-face.face-bottom {
        width: 80px;
        height: 16px;
      }

      /* Ajustar la profundidad del hexágono */
      .segment-1 {
        transform: translateZ(60px) rotateY(0deg);
      }

      .segment-2 {
        transform: rotateY(60deg) translateZ(60px);
      }

      .segment-3 {
        transform: rotateY(120deg) translateZ(60px);
      }

      .segment-4 {
        transform: rotateY(180deg) translateZ(60px);
      }

      .segment-5 {
        transform: rotateY(240deg) translateZ(60px);
      }

      .segment-6 {
        transform: rotateY(300deg) translateZ(60px);
      }

      .glow-ring {
        width: 220px;
        height: 220px;
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

  if write_file_with_confirm "src/public/index.html" "$html_content"; then
    log "SUCCESS" "Archivo src/public/index.html creado correctamente"
    return 0
  else
    log "ERROR" "Error al crear el archivo src/public/index.html"
    return 1
  fi
}

validate_dependencies() {
  log "INFO" "Validando dependencias necesarias"

  if [[ ! -f "$PROJECT_ROOT/generator/common/confirm-action.sh" ]]; then
    log "ERROR" "No se encontró el archivo confirm-action.sh"
    return 1
  fi

  log "SUCCESS" "Todas las dependencias están disponibles"
  return 0
}

validate_html_content() {
  log "INFO" "Validando contenido HTML"

  # Verificar si el placeholder MI_HTML necesita ser reemplazado
  if [[ -f "src/public/index.html" ]]; then
    if grep -q "MI_HTML" "src/public/index.html"; then
      log "WARN" "El archivo contiene el placeholder 'MI_HTML' - considera reemplazarlo con contenido real"
    fi
  fi

  log "SUCCESS" "Validación de contenido HTML completada"
  return 0
}

# ========================
# FUNCIÓN PRINCIPAL
# ========================
main() {
  log "INFO" "=== Iniciando generación de archivo HTML ==="

  if ! validate_dependencies; then
    log "ERROR" "Falló la validación de dependencias"
    exit 1
  fi

  if ! create_public_directory; then
    log "ERROR" "Error al preparar el directorio público"
    exit 1
  fi

  if ! create_html_file; then
    log "ERROR" "Error al crear el archivo HTML"
    exit 1
  fi

  validate_html_content

  log "SUCCESS" "=== Generación de archivo HTML completada exitosamente ==="
}

# ========================
# EXECUTION LOGIC
# ========================
# Si se llama directamente con bash
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
  main "$@"
fi

# Si se hace source y hay condiciones específicas
if [[ "${BASH_SOURCE[0]}" != "${0}" && (-n "${CREATE_HTML:-}" || $# -gt 0) ]]; then
  main "$@"
fi
