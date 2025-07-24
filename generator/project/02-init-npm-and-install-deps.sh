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

# Verificar y agregar scripts a package.json
echo "🛠️ Verificando scripts y configuraciones en package.json..."

# Usamos jq para editar de forma segura
if ! command -v jq &>/dev/null; then
  echo "❌ Error: 'jq' no está instalado. Instalalo con: sudo apt install jq o brew install jq"
  exit 1
fi

tmp_file="package.tmp.json"

# Asegurar que "scripts" exista
jq 'if .scripts == null then .scripts = {} else . end' package.json >"$tmp_file" && mv "$tmp_file" package.json

# Agregar script start si no existe
if [ "$(jq '.scripts.start' package.json)" = "null" ]; then
  jq '.scripts.start = "node src/index.js"' package.json >"$tmp_file" && mv "$tmp_file" package.json
  echo "✅ Script start agregado"
fi

# Agregar script dev si no existe
if [ "$(jq '.scripts.dev' package.json)" = "null" ]; then
  jq '.scripts.dev = "nodemon src/index.js"' package.json >"$tmp_file" && mv "$tmp_file" package.json
  echo "✅ Script dev agregado"
fi

# Verificar y agregar "type": "module" si no existe
if [ "$(jq -r '.type // empty' package.json)" != "module" ]; then
  jq '.type = "module"' package.json >"$tmp_file" && mv "$tmp_file" package.json
  echo "✅ Campo 'type: module' agregado a package.json"
fi

echo "✅ Configuración de proyecto completada."
