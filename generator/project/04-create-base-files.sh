#!/bin/bash
# generator/project/04-create-base-files.sh

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
create_file_with_content() {
  local file_path="$1"
  local content="$2"
  local is_optional="${3:-false}"

  if [[ -f "$file_path" ]]; then
    log "WARN" "Archivo '$file_path' ya existe, no se sobrescribirá"
    return 0
  fi

  if echo "$content" >"$file_path" 2>/dev/null; then
    log "SUCCESS" "Archivo '$file_path' creado correctamente"
    return 0
  else
    if [[ "$is_optional" == true ]]; then
      log "WARN" "No se pudo crear archivo opcional '$file_path'"
      return 0
    else
      log "ERROR" "Error creando archivo requerido '$file_path'"
      return 1
    fi
  fi
}

create_base_files() {
  log "INFO" "Creando archivos base del proyecto"

  local created_count=0
  local existing_count=0
  local error_count=0

  for file in "${BASE_FILES[@]}"; do
    if [[ -f "$file" ]]; then
      ((existing_count++))
      log "INFO" "Archivo '$file' ya existe"
    else
      local content=""
      case "$file" in
      ".gitignore")
        content=$(get_gitignore_content)
        ;;
      ".gitattributes")
        content=$(get_gitattributes_content)
        ;;
      ".prettierrc")
        content=$(get_prettierrc_content)
        ;;
      "README.md")
        content=$(get_readme_content)
        ;;
      *)
        # Para archivos sin contenido específico, crear vacío
        content=""
        ;;
      esac

      if create_file_with_content "$file" "$content"; then
        ((created_count++))
      else
        ((error_count++))
      fi
    fi
  done

  if [[ $error_count -gt 0 ]]; then
    log "ERROR" "Error creando $error_count archivos base"
    return 1
  fi

  log "SUCCESS" "Archivos base procesados (creados: $created_count, existentes: $existing_count)"
  return 0
}

create_optional_files() {
  if [[ "$CREATE_OPTIONAL_FILES" != true ]]; then
    log "INFO" "Omitiendo creación de archivos opcionales (CREATE_OPTIONAL_FILES != true)"
    return 0
  fi

  log "INFO" "Creando archivos opcionales del proyecto"

  local created_count=0
  local existing_count=0

  for file in "${OPTIONAL_FILES[@]}"; do
    if [[ -f "$file" ]]; then
      ((existing_count++))
      log "INFO" "Archivo opcional '$file' ya existe"
    else
      local content=""
      case "$file" in
      ".eslintrc.json")
        content='{"extends": ["eslint:recommended"], "env": {"node": true, "es2022": true}, "parserOptions": {"ecmaVersion": 2022, "sourceType": "module"}}'
        ;;
      ".env.example")
        content="# Ejemplo de variables de entorno\nPORT=3000\nNODE_ENV=development"
        ;;
      "CHANGELOG.md")
        content="# Changelog\n\n## [1.0.0] - $(date +%Y-%m-%d)\n\n### Added\n- Proyecto inicial generado"
        ;;
      "CONTRIBUTING.md")
        content="# Guía de Contribución\n\n## Cómo Contribuir\n\n1. Fork el proyecto\n2. Crea tu rama de feature\n3. Realiza tus cambios\n4. Envía un pull request"
        ;;
      "LICENSE")
        content="MIT License\n\nCopyright (c) $(date +%Y)\n\nPermission is hereby granted, free of charge, to any person obtaining a copy of this software and associated documentation files..."
        ;;
      *)
        content=""
        ;;
      esac

      if create_file_with_content "$file" "$content" true; then
        ((created_count++))
      fi
    fi
  done

  log "SUCCESS" "Archivos opcionales procesados (creados: $created_count, existentes: $existing_count)"
  return 0
}

validate_created_files() {
  log "INFO" "Validando archivos creados"

  local missing_files=()
  local invalid_files=()

  for file in "${BASE_FILES[@]}"; do
    if [[ ! -f "$file" ]]; then
      missing_files+=("$file")
    elif [[ ! -s "$file" && "$file" != ".gitattributes" ]]; then
      # .gitattributes puede estar vacío legitimamente
      invalid_files+=("$file")
    fi
  done

  if [[ ${#missing_files[@]} -gt 0 ]]; then
    log "ERROR" "Archivos faltantes después de la creación:"
    for missing_file in "${missing_files[@]}"; do
      log "ERROR" "  - $missing_file"
    done
    return 1
  fi

  if [[ ${#invalid_files[@]} -gt 0 ]]; then
    log "WARN" "Archivos posiblemente vacíos (revisar):"
    for invalid_file in "${invalid_files[@]}"; do
      log "WARN" "  - $invalid_file"
    done
  fi

  log "SUCCESS" "Validación de archivos completada"
  return 0
}

show_created_files_summary() {
  log "INFO" "Resumen de archivos en el proyecto:"

  for file in "${BASE_FILES[@]}"; do
    if [[ -f "$file" ]]; then
      local file_size
      file_size=$(wc -c <"$file" 2>/dev/null || echo "0")
      local status="✅"
      if [[ "$file_size" -eq 0 ]]; then
        status="⚠️ (vacío)"
      fi
      log "INFO" "  $status $file ($file_size bytes)"
    else
      log "INFO" "  ❌ $file (no encontrado)"
    fi
  done

  if [[ "$CREATE_OPTIONAL_FILES" == true ]]; then
    log "INFO" "Archivos opcionales:"
    for file in "${OPTIONAL_FILES[@]}"; do
      if [[ -f "$file" ]]; then
        local file_size
        file_size=$(wc -c <"$file" 2>/dev/null || echo "0")
        log "INFO" "  ✅ $file ($file_size bytes)"
      fi
    done
  fi
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
  log "INFO" "=== CREACIÓN DE ARCHIVOS BASE ==="

  # Procesar argumentos
  for arg in "$@"; do
    case "$arg" in
    -h | --help)
      show_help
      return 0
      ;;
    --optional)
      export CREATE_OPTIONAL_FILES=true
      ;;
    esac
  done

  local start_time
  start_time=$(date +%s)

  # Ejecutar creación de archivos
  create_base_files || {
    log "ERROR" "Error creando archivos base"
    return 1
  }

  create_optional_files || {
    log "WARN" "Advertencias creando archivos opcionales (no crítico)"
  }

  validate_created_files || {
    log "ERROR" "Validación de archivos falló"
    return 1
  }

  show_created_files_summary

  local end_time
  end_time=$(date +%s)
  local duration=$((end_time - start_time))

  log "SUCCESS" "=== CREACIÓN DE ARCHIVOS BASE COMPLETADA ==="
  log "SUCCESS" "Tiempo total: ${duration}s"
  log "INFO" "Total de archivos base: ${#BASE_FILES[@]}"

  if [[ "$CREATE_OPTIONAL_FILES" == true ]]; then
    log "INFO" "Total de archivos opcionales: ${#OPTIONAL_FILES[@]}"
  fi
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
