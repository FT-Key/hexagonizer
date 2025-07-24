#!/bin/bash

# Verificar si Node.js está instalado
if ! command -v node &>/dev/null; then
  echo "❌ Node.js no está instalado. Por favor instálalo antes de continuar."
  exit 1
fi

echo "✅ Node.js está instalado. Versión: $(node -v)"

# Verificar si es un proyecto Node.js (presencia de package.json)
if [ -f "package.json" ]; then
  echo "📦 Ya es un proyecto Node.js (package.json encontrado)."
else
  echo "📦 No se detectó un proyecto Node.js. Inicializando con 'npm init -y'..."
  npm init -y
  echo "✅ Proyecto Node.js inicializado."
fi
