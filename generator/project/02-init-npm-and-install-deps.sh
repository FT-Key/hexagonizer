#!/bin/bash
# hexagonizer/project/01-init-npm-and-install-deps.sh

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

echo "✅ Configuración de proyecto completada."
