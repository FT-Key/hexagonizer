#!/bin/bash
# update-index.sh - Actualiza el archivo index.js con rutas de entidad
set -e

# =============================================================================
# CONFIGURACIÓN Y VALIDACIONES
# =============================================================================

readonly INDEX_FILE="src/index.js"

validate_environment() {
  if [[ ! -f "$INDEX_FILE" ]]; then
    echo "⚠️  No se encontró index.js en src/"
    exit 0
  fi

  if [[ -z "${entity:-}" ]]; then
    echo "❌ Variable 'entity' no definida"
    exit 1
  fi
}

initialize_variables() {
  entity_lower=$(echo "$entity" | tr '[:upper:]' '[:lower:]')
  entity_pascal=$(echo "$entity" | sed -E 's/(^|-)([a-z])/\U\2/g')
}

# =============================================================================
# UTILIDADES
# =============================================================================

# Utilidad para insertar si no existe
add_unique_line() {
  local line="$1"
  grep -Fqx "$line" "$INDEX_FILE" || echo "$line" >>"$INDEX_FILE"
}

# Utilidad para crear archivo temporal y moverlo
apply_awk_transformation() {
  local awk_script="$1"
  local success_message="$2"

  awk "$awk_script" "$INDEX_FILE" >"$INDEX_FILE.tmp" && mv "$INDEX_FILE.tmp" "$INDEX_FILE"
  echo "$success_message"
}

# =============================================================================
# GESTIÓN DE IMPORTS
# =============================================================================

setup_imports() {
  echo "📦 Configurando imports..."

  declare -A imports=(
    ["routes"]="import ${entity_lower}Routes from './interfaces/http/${entity_lower}/${entity_lower}.routes.js';"
    ["queryConfig"]="import { ${entity_lower}QueryConfig } from './interfaces/http/${entity_lower}/query-${entity_lower}-config.js';"
    ["middleware"]="import { createQueryMiddlewares } from './interfaces/http/middlewares/query.middlewares.js';"
  )

  for key in "${!imports[@]}"; do
    local line="${imports[$key]}"

    if grep -Fq "$line" "$INDEX_FILE"; then
      echo "🔹 Import '$key' ya existe."
    else
      add_import_after_last_import "$line"
      echo "✅ Import '$key' agregado"
    fi
  done
}

add_import_after_last_import() {
  local new_import="$1"

  apply_awk_transformation "
    BEGIN { added=0 }
    /^import / {
      last_import=NR
    }
    { lines[NR]=\$0 }
    END {
      for (i=1; i<=NR; i++) {
        print lines[i]
        if (i == last_import && !added) {
          print \"$new_import\"
          added=1
        }
      }
    }
  " "Import añadido después de la última declaración import"
}

# =============================================================================
# CONFIGURACIÓN DEL ROUTER
# =============================================================================

setup_router_wrapper() {
  echo "🔧 Configurando router wrapper..."

  local router_wrapper_block="const ${entity_lower}RouterWithMiddlewares = wrapRouterWithFlexibleMiddlewares(${entity_lower}Routes, {
  globalMiddlewares: createQueryMiddlewares(${entity_lower}QueryConfig),
  excludePathsByMiddleware,
  routeMiddlewares,
});"

  # Verificar si ya existe
  if grep -Fq "const ${entity_lower}RouterWithMiddlewares" "$INDEX_FILE"; then
    echo "🔹 Bloque del router ya existe."
    return 0
  fi

  # Mostrar diagnóstico
  echo "📊 Estado actual del archivo:"
  echo "- Total de líneas: $(wc -l <"$INDEX_FILE")"
  echo "- Declaraciones const: $(grep -c "^const" "$INDEX_FILE" || echo "0")"
  echo "- Líneas con 'router': $(grep -c -i "router" "$INDEX_FILE" || echo "0")"
  echo ""

  # Intentar insertar
  if add_router_wrapper_block "$router_wrapper_block"; then
    echo "✅ Router wrapper configurado exitosamente"
  else
    echo "❌ Falló la configuración del router wrapper"

    # Estrategia de fallback: insertar al final
    echo "🔄 Aplicando estrategia de fallback..."
    echo "" >>"$INDEX_FILE"
    echo "$router_wrapper_block" >>"$INDEX_FILE"
    echo "" >>"$INDEX_FILE"

    if grep -q "const ${entity_lower}RouterWithMiddlewares" "$INDEX_FILE"; then
      echo "✅ Router insertado al final del archivo como fallback"
    else
      echo "❌ Falló completamente la inserción del router"
      return 1
    fi
  fi
}

add_router_wrapper_block() {
  local block="$1"

  echo "🔧 Intentando insertar router wrapper..."
  echo "📝 Bloque a insertar:"
  echo "$block"
  echo ""

  # Estrategia 1: Buscar patrones específicos
  local inserted=false
  local patterns=(
    "^const publicRouter"
    "^const app"
    "^app\.use"
    "routes:[[:space:]]*\["
    "^const.*Server"
    "^const.*server"
  )

  for pattern in "${patterns[@]}"; do
    if grep -q "$pattern" "$INDEX_FILE"; then
      echo "✅ Encontrado patrón: $pattern"

      awk -v block="$block" -v pat="$pattern" '
        BEGIN { added=0 }
        $0 ~ pat && !added {
          print block
          print ""
          added=1
        }
        { print }
      ' "$INDEX_FILE" >"$INDEX_FILE.tmp"

      if [[ -s "$INDEX_FILE.tmp" ]]; then
        mv "$INDEX_FILE.tmp" "$INDEX_FILE"
        inserted=true
        echo "✅ Router insertado usando patrón: $pattern"
        break
      else
        rm -f "$INDEX_FILE.tmp"
      fi
    fi
  done

  # Estrategia 2: Insertar después de la última declaración const
  if [[ "$inserted" == false ]]; then
    echo "⚠️  No se encontraron patrones específicos, insertando después de último const..."

    awk -v block="$block" '
      BEGIN { last_const_line=0 }
      /^const / { last_const_line=NR }
      { lines[NR]=$0 }
      END {
        if (last_const_line > 0) {
          for (i=1; i<=NR; i++) {
            print lines[i]
            if (i == last_const_line) {
              print ""
              print block
              print ""
            }
          }
        } else {
          for (i=1; i<=NR; i++) print lines[i]
          print ""
          print block
        }
      }
    ' "$INDEX_FILE" >"$INDEX_FILE.tmp" && mv "$INDEX_FILE.tmp" "$INDEX_FILE"

    inserted=true
    echo "✅ Router insertado después de la última declaración const"
  fi

  # Verificar que se insertó correctamente
  if grep -q "const ${entity_lower}RouterWithMiddlewares" "$INDEX_FILE"; then
    echo "✅ Verificación: Router wrapper insertado correctamente"
  else
    echo "❌ Error: Router wrapper no se insertó correctamente"
    return 1
  fi
}

# =============================================================================
# CONFIGURACIÓN DE RUTAS
# =============================================================================

setup_server_route() {
  echo "🛣️  Configurando ruta del servidor..."

  local route_line="    { path: '/${entity_lower}', handler: ${entity_lower}RouterWithMiddlewares },"

  if grep -Fq "$route_line" "$INDEX_FILE"; then
    echo "🔹 Ruta ya existe en servidor."
  else
    add_server_route "$route_line"
    echo "✅ Ruta agregada al servidor"
  fi
}

add_server_route() {
  local new_route="$1"

  apply_awk_transformation "
    BEGIN { inRoutes=0; added=0 }
    /routes:[[:space:]]*\[/ { inRoutes=1 }
    inRoutes && /^\s*\]/ && !added {
      print \"$new_route\"
      added=1
    }
    { print }
  " "Ruta agregada al array de rutas del servidor"
}

# =============================================================================
# FUNCIONES DE DIAGNÓSTICO
# =============================================================================

diagnose_index_structure() {
  echo "🔍 Diagnosticando estructura del index.js..."

  echo "📋 Líneas relevantes encontradas:"
  echo "--- Imports ---"
  grep -n "^import" "$INDEX_FILE" | head -5
  echo "--- Routers/Constants ---"
  grep -n -E "(const.*router|const.*Router|const.*app|app\.use)" "$INDEX_FILE" | head -5
  echo "--- Routes array ---"
  grep -n -A2 -B2 "routes.*\[" "$INDEX_FILE"
  echo ""
}

# Función mejorada para encontrar el lugar correcto para insertar
find_insertion_point_for_router() {
  # Buscar diferentes patrones posibles
  local patterns=(
    "^const publicRouter"
    "^const app"
    "^app\.use"
    "routes:[[:space:]]*\["
    "^const.*router.*="
    "^const.*Router.*="
  )

  for pattern in "${patterns[@]}"; do
    if grep -q "$pattern" "$INDEX_FILE"; then
      echo "✅ Patrón encontrado: $pattern"
      return 0
    fi
  done

  echo "❌ No se encontró un patrón adecuado para insertar el router"
  return 1
}

# =============================================================================
# FUNCIONES DE VERIFICACIÓN
# =============================================================================

verify_updates() {
  echo "🔍 Verificando actualizaciones..."

  local checks=(
    "import ${entity_lower}Routes"
    "import { ${entity_lower}QueryConfig }"
    "const ${entity_lower}RouterWithMiddlewares"
    "path: '/${entity_lower}'"
  )

  local all_good=true

  for check in "${checks[@]}"; do
    if grep -q "$check" "$INDEX_FILE"; then
      echo "✅ Verificado: $check"
    else
      echo "❌ Falta: $check"

      # Búsqueda más detallada para debugging
      echo "   🔍 Buscando variaciones..."
      if [[ "$check" == "const ${entity_lower}RouterWithMiddlewares" ]]; then
        echo "   📋 Líneas que contienen '${entity_lower}Router':"
        grep -n "${entity_lower}Router" "$INDEX_FILE" || echo "   - Ninguna encontrada"
        echo "   📋 Líneas que contienen 'RouterWithMiddlewares':"
        grep -n "RouterWithMiddlewares" "$INDEX_FILE" || echo "   - Ninguna encontrada"
      fi

      all_good=false
    fi
  done

  if [[ "$all_good" == true ]]; then
    echo "🎉 Todas las verificaciones pasaron correctamente"
  else
    echo "⚠️  Algunas verificaciones fallaron"

    # Mostrar las últimas 10 líneas del archivo para debugging
    echo ""
    echo "📄 Últimas 10 líneas del archivo:"
    tail -10 "$INDEX_FILE"
    echo ""

    return 1
  fi
}

# =============================================================================
# FUNCIÓN PRINCIPAL
# =============================================================================

main() {
  echo "🚀 Actualizando index.js para la entidad: $entity"

  # Validaciones iniciales
  validate_environment
  initialize_variables

  # Crear backup del archivo original
  cp "$INDEX_FILE" "$INDEX_FILE.backup"
  echo "💾 Backup creado: $INDEX_FILE.backup"

  # Aplicar todas las actualizaciones
  setup_imports
  setup_router_wrapper
  setup_server_route

  # Verificar que todo se aplicó correctamente
  if verify_updates; then
    rm "$INDEX_FILE.backup"
    echo "✅ index.js actualizado correctamente para '$entity'"
    echo "🗑️  Backup eliminado (actualización exitosa)"
  else
    echo "⚠️  Hubo problemas en la verificación. Backup conservado."
    exit 1
  fi
}

# =============================================================================
# FUNCIÓN DE AYUDA
# =============================================================================

show_help() {
  cat <<EOF
Uso: $0

Este script actualiza el archivo src/index.js para incluir las rutas
de una nueva entidad.

Variables requeridas:
  entity    - Nombre de la entidad (ej: "user", "product")

Ejemplo:
  entity="user" $0

El script:
1. Agrega los imports necesarios
2. Configura el router con middlewares
3. Añade la ruta al servidor
4. Verifica que todo se haya aplicado correctamente

EOF
}

# =============================================================================
# PUNTO DE ENTRADA
# =============================================================================

# Mostrar ayuda si se solicita
if [[ "${1:-}" == "--help" || "${1:-}" == "-h" ]]; then
  show_help
  exit 0
fi

# Ejecutar solo si el script es llamado directamente
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
  main "$@"
fi

# Llamada implícita si fue sourced desde otro script
if [[ -n "${entity:-}" ]]; then
  main "$@"
fi
