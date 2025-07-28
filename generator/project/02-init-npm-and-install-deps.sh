#!/bin/bash
# hexagonizer/project/01-init-npm-and-install-deps.sh

set -e

# Inicializar proyecto si no existe package.json
if [ ! -f package.json ]; then
  echo "📦 Inicializando proyecto Node..."
  npm init -y
fi

echo "📦 Verificando e instalando dependencias necesarias..."

# Instalar express primero
if ! grep -q '"express"' package.json; then
  echo "📦 Instalando express..."
  npm install express
fi

# Lista de dependencias restantes (sin express)
declare -a dependencies=("path-to-regexp" "cors" "helmet" "morgan" "dotenv")
for dep in "${dependencies[@]}"; do
  if ! grep -q "\"$dep\"" package.json; then
    echo "📦 Instalando $dep..."
    npm install "$dep"
  fi
done

# Dependencias de desarrollo
if ! grep -q '"nodemon"' package.json; then
  echo "🛠️ Instalando nodemon (dev)..."
  npm install --save-dev nodemon
fi

# Crear archivos .env y .env.production si no existen
for env_file in ".env" ".env.production"; do
  if [ ! -f "$env_file" ]; then
    echo "🔧 Creando archivo $env_file"
    echo "# Variables de entorno" >"$env_file"
  fi
done

# Verificar y agregar scripts a package.json usando Node.js
echo "🛠️ Verificando scripts y configuraciones en package.json..."

node -e '
const fs = require("fs");
const path = "./package.json";
try {
  const pkg = JSON.parse(fs.readFileSync(path, "utf8"));
  pkg.scripts = pkg.scripts || {};
  if (!pkg.scripts.start) pkg.scripts.start = "node src/index.js";
  if (!pkg.scripts.dev) pkg.scripts.dev = "nodemon src/index.js";
  if (pkg.type !== "module") pkg.type = "module";
  fs.writeFileSync(path, JSON.stringify(pkg, null, 2) + "\n");
  console.log("✅ package.json actualizado con scripts y type: module");
} catch (err) {
  console.error("❌ Error leyendo o escribiendo package.json:", err);
  process.exit(1);
}
'

# Verificación de versión de Node.js instalada vs LTS
echo "🧪 Verificando compatibilidad de versiones de Node.js..."

# Obtener versión local de Node.js
local_version=$(node -v | sed 's/v//')
echo "🔢 Versión actual de Node.js: $local_version"

# Comprobar si jq está instalado
if ! command -v jq &>/dev/null; then
  echo "⚠️  El comando 'jq' no está disponible. No se puede verificar la última versión LTS de Node.js."
else
  # Obtener última versión estable (LTS) de Node.js
  latest_version=$(curl -s https://nodejs.org/dist/index.json | jq -r '[.[] | select(.lts != false)][0].version' | sed 's/v//')

  if [ -z "$latest_version" ]; then
    echo "⚠️  No se pudo obtener la última versión estable de Node.js para comparación."
  else
    echo "🔍 Última versión LTS disponible: $latest_version"

    if [[ "$local_version" != "$latest_version" ]]; then
      echo "⚠️  Tu versión de Node.js ($local_version) difiere de la última LTS ($latest_version)."
      echo "🔁 Considera actualizar tu entorno si encuentras problemas de compatibilidad con dependencias modernas."
    else
      echo "✅ Estás usando la última versión estable de Node.js."
    fi
  fi
fi

echo "✅ Configuración de proyecto completada."
