#!/bin/bash
# generator/project/04-create-base-files.sh

set -e

source "$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)/../common/logging.sh"

# ========================
# FILE CONFIGURATION
# ========================
# Archivos base requeridos del proyecto
readonly BASE_FILES=(
  ".gitignore"
  ".gitattributes"
  ".prettierrc"
  "README.md"
)

# Archivos opcionales que pueden crearse
readonly OPTIONAL_FILES=(
  ".eslintrc.json"
  ".env.example"
  "CHANGELOG.md"
  "CONTRIBUTING.md"
  "LICENSE"
)

# ========================
# FILE CONTENT TEMPLATES
# ========================
get_gitignore_content() {
  cat <<'EOF'
# Dependencies
node_modules/
npm-debug.log*
yarn-debug.log*
yarn-error.log*

# Runtime data
pids
*.pid
*.seed
*.pid.lock

# Coverage directory used by tools like nyc
coverage/
*.lcov

# Environment variables
.env
.env.local
.env.development.local
.env.test.local
.env.production.local

# Logs
logs
*.log

# OS generated files
.DS_Store
.DS_Store?
._*
.Spotlight-V100
.Trashes
ehthumbs.db
Thumbs.db

# IDE
.vscode/
.idea/
*.swp
*.swo

# Build outputs
dist/
build/
.next/
out/

# Temporary folders
tmp/
temp/
EOF
}

get_gitattributes_content() {
  cat <<'EOF'
# Auto detect text files and perform LF normalization
* text=auto

# JavaScript files should always use LF for line endings
*.js text eol=lf
*.mjs text eol=lf
*.json text eol=lf

# Shell scripts should always use LF
*.sh text eol=lf

# Markdown files
*.md text eol=lf

# Ensure binary files are not modified
*.png binary
*.jpg binary
*.jpeg binary
*.gif binary
*.ico binary
*.pdf binary
EOF
}

get_prettierrc_content() {
  cat <<'EOF'
{
  "semi": true,
  "trailingComma": "es5",
  "singleQuote": true,
  "printWidth": 80,
  "tabWidth": 2,
  "useTabs": false,
  "bracketSpacing": true,
  "arrowParens": "avoid",
  "endOfLine": "lf"
}
EOF
}

get_readme_content() {
  local project_name
  project_name=$(basename "$(pwd)" 2>/dev/null || echo "mi-proyecto")

  cat <<EOF
# $project_name

## Descripción

Proyecto Node.js con arquitectura hexagonal generado automáticamente.

## Estructura del Proyecto

\`\`\`
src/
├── config/          # Configuraciones de la aplicación
├── domain/          # Lógica de negocio y entidades
├── infrastructure/  # Implementaciones de infraestructura
├── interfaces/      # Controladores y middlewares HTTP
├── application/     # Casos de uso de la aplicación
└── utils/           # Utilidades compartidas
\`\`\`

## Instalación

\`\`\`bash
npm install
\`\`\`

## Uso

### Desarrollo
\`\`\`bash
npm run dev
\`\`\`

### Producción
\`\`\`bash
npm start
\`\`\`

## Scripts Disponibles

- \`npm run dev\` - Ejecuta el servidor en modo desarrollo con nodemon
- \`npm start\` - Ejecuta el servidor en modo producción

## Tecnologías

- Node.js
- Express.js
- ES6 Modules

## Contribución

1. Fork el proyecto
2. Crea tu rama de feature (\`git checkout -b feature/AmazingFeature\`)
3. Commit tus cambios (\`git commit -m 'Add some AmazingFeature'\`)
4. Push a la rama (\`git push origin feature/AmazingFeature\`)
5. Abre un Pull Request

## Licencia

Proyecto generado con arquitectura hexagonal.
EOF
}

# ========================
# FILE CREATION FUNCTIONS
# ========================
create_base_files() {
  for file in "${BASE_FILES[@]}"; do
    if [[ ! -f "$file" ]]; then
      local content=""
      case "$file" in
      ".gitignore") content=$(get_gitignore_content) ;;
      ".gitattributes") content=$(get_gitattributes_content) ;;
      ".prettierrc") content=$(get_prettierrc_content) ;;
      "README.md") content=$(get_readme_content) ;;
      esac
      echo "$content" >"$file"
    fi
  done
  log "SUCCESS" "Archivos base creados"
}

create_optional_files() {
  [[ "$CREATE_OPTIONAL_FILES" != true ]] && return 0

  for file in "${OPTIONAL_FILES[@]}"; do
    if [[ ! -f "$file" ]]; then
      local content=""
      case "$file" in
      ".eslintrc.json") content='{"extends": ["eslint:recommended"], "env": {"node": true, "es2022": true}, "parserOptions": {"ecmaVersion": 2022, "sourceType": "module"}}' ;;
      ".env.example") content="# Ejemplo de variables de entorno\nPORT=3000\nNODE_ENV=development" ;;
      "CHANGELOG.md") content="# Changelog\n\n## [1.0.0] - $(date +%Y-%m-%d)\n\n### Added\n- Proyecto inicial generado" ;;
      "CONTRIBUTING.md") content="# Guía de Contribución\n\n## Cómo Contribuir\n\n1. Fork el proyecto\n2. Crea tu rama de feature\n3. Realiza tus cambios\n4. Envía un pull request" ;;
      "LICENSE") content="MIT License\n\nCopyright (c) $(date +%Y)" ;;
      esac
      echo -e "$content" >"$file"
    fi
  done
  log "SUCCESS" "Archivos opcionales creados"
}

show_help() {
  cat <<EOF
Uso: $0 [OPCIONES]

OPCIONES:
  --optional       Crear también archivos opcionales
  -h, --help       Muestra esta ayuda

DESCRIPCIÓN:
  Este script crea los archivos base necesarios para un proyecto Node.js
  con configuraciones estándar.

ARCHIVOS BASE (${#BASE_FILES[@]}):
$(printf "  %s\n" "${BASE_FILES[@]}")

ARCHIVOS OPCIONALES (${#OPTIONAL_FILES[@]}):
$(printf "  %s\n" "${OPTIONAL_FILES[@]}")

VARIABLES DE ENTORNO:
  CREATE_OPTIONAL_FILES=true    Crear archivos opcionales

EJEMPLO:
  $0                        # Solo archivos base
  $0 --optional             # Base + opcionales
  CREATE_OPTIONAL_FILES=true $0  # Base + opcionales
EOF
}

# ========================
# MAIN FUNCTION
# ========================
main() {
  for arg in "$@"; do
    case "$arg" in -h|--help) show_help; return 0;; --optional) export CREATE_OPTIONAL_FILES=true;; esac
  done

  create_base_files
  create_optional_files
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
