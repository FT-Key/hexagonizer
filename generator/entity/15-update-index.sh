#!/bin/bash
# update-index.sh - Actualiza el archivo index.js con rutas de entidad
set -e

source "$PROJECT_ROOT/generator/common/logging.sh"

readonly INDEX_FILE="src/index.js"

validate_environment() {
  if [[ ! -f "$INDEX_FILE" ]]; then
    log "WARN" "No se encontró '$INDEX_FILE'. Nada que actualizar."
    exit 0
  fi

  if [[ -z "${entity:-}" ]]; then
    log "ERROR" "Variable 'entity' no definida. Abortando."
    exit 1
  fi
}

initialize_variables() {
  entity_lower=$(echo "$entity" | tr '[:upper:]' '[:lower:]')
  entity_pascal=$(echo "$entity" | sed -E 's/(^|-)([a-z])/\U\2/g')
  log "INFO" "Variables inicializadas: entity_lower='$entity_lower', entity_pascal='$entity_pascal'"
}

add_unique_line() {
  local line="$1"
  if grep -Fqx "$line" "$INDEX_FILE"; then
    log "INFO" "Línea ya existe, no se añade: $line"
  else
    echo "$line" >>"$INDEX_FILE"
    log "SUCCESS" "Línea agregada: $line"
  fi
}

apply_awk_transformation() {
  local awk_script="$1"
  local success_message="$2"

  awk "$awk_script" "$INDEX_FILE" >"$INDEX_FILE.tmp" && mv "$INDEX_FILE.tmp" "$INDEX_FILE"
  log "SUCCESS" "$success_message"
}

setup_imports() {
  log "INFO" "Configurando imports..."

  declare -A imports=(
    ["routes"]="import ${entity_lower}Routes from './interfaces/http/${entity_lower}/${entity_lower}.routes.js';"
    ["queryConfig"]="import { ${entity_lower}QueryConfig } from './interfaces/http/${entity_lower}/query-${entity_lower}-config.js';"
    ["middleware"]="import { createQueryMiddlewares } from './interfaces/http/middlewares/query.middlewares.js';"
  )

  for key in "${!imports[@]}"; do
    local line="${imports[$key]}"
    if grep -Fq "$line" "$INDEX_FILE"; then
      log "INFO" "Import '$key' ya existe."
    else
      add_import_after_last_import "$line"
      log "SUCCESS" "Import '$key' agregado."
    fi
  done
}

add_import_after_last_import() {
  local new_import="$1"
  apply_awk_transformation "
    BEGIN { added=0 }
    /^import / { last_import=NR }
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

setup_router_wrapper() {
  log "INFO" "Configurando router wrapper..."

  local router_wrapper_block="const ${entity_lower}RouterWithMiddlewares = wrapRouterWithFlexibleMiddlewares(${entity_lower}Routes, {
  globalMiddlewares: createQueryMiddlewares(${entity_lower}QueryConfig),
  excludePathsByMiddleware,
  routeMiddlewares,
});"

  if grep -Fq "const ${entity_lower}RouterWithMiddlewares" "$INDEX_FILE"; then
    log "INFO" "Bloque del router ya existe, se omite inserción."
    return 0
  fi

  log "INFO" "Estado actual de '$INDEX_FILE':"
  log "INFO" "- Total de líneas: $(wc -l <"$INDEX_FILE")"
  log "INFO" "- Declaraciones const: $(grep -c '^const' "$INDEX_FILE" || echo '0')"
  log "INFO" "- Líneas con 'router': $(grep -c -i 'router' "$INDEX_FILE" || echo '0')"

  if add_router_wrapper_block "$router_wrapper_block"; then
    log "SUCCESS" "Router wrapper configurado exitosamente."
  else
    log "ERROR" "Falló la configuración del router wrapper."
    log "INFO" "Aplicando estrategia de fallback: insertar al final del archivo..."

    echo "" >>"$INDEX_FILE"
    echo "$router_wrapper_block" >>"$INDEX_FILE"
    echo "" >>"$INDEX_FILE"

    if grep -q "const ${entity_lower}RouterWithMiddlewares" "$INDEX_FILE"; then
      log "SUCCESS" "Router insertado al final del archivo como fallback."
    else
      log "ERROR" "Error: Falló completamente la inserción del router."
      return 1
    fi
  fi
}

add_router_wrapper_block() {
  local block="$1"
  log "INFO" "Intentando insertar router wrapper..."
  log "INFO" "Bloque a insertar:"

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
      log "SUCCESS" "Patrón encontrado: $pattern"

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
        log "SUCCESS" "Router insertado usando patrón: $pattern"
        break
      else
        rm -f "$INDEX_FILE.tmp"
      fi
    fi
  done

  if [[ "$inserted" == false ]]; then
    log "WARN" "No se encontraron patrones específicos, insertando después de última declaración const..."

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
    log "SUCCESS" "Router insertado después de la última declaración const."
  fi

  if grep -q "const ${entity_lower}RouterWithMiddlewares" "$INDEX_FILE"; then
    log "SUCCESS" "Verificación: router wrapper insertado correctamente."
  else
    log "ERROR" "Error: router wrapper no se insertó correctamente."
    return 1
  fi
}

setup_server_route() {
  log "INFO" "Configurando ruta del servidor..."

  local route_line="    { path: '/${entity_lower}', handler: ${entity_lower}RouterWithMiddlewares },"

  if grep -Fq "$route_line" "$INDEX_FILE"; then
    log "INFO" "Ruta ya existe en servidor, no se agrega."
  else
    add_server_route "$route_line"
    log "SUCCESS" "Ruta agregada al servidor."
  fi
}

add_server_route() {
  local new_route="$1"
  apply_awk_transformation() {
    local awk_script="$1"
    local success_message="$2"
    awk "$awk_script" "$INDEX_FILE" >"$INDEX_FILE.tmp" && mv "$INDEX_FILE.tmp" "$INDEX_FILE"
    log "SUCCESS" "$success_message"
  }

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

verify_updates() {
  log "INFO" "Verificando actualizaciones..."

  local checks=(
    "import ${entity_lower}Routes"
    "import { ${entity_lower}QueryConfig }"
    "const ${entity_lower}RouterWithMiddlewares"
    "path: '/${entity_lower}'"
  )

  local all_good=true

  for check in "${checks[@]}"; do
    if grep -q "$check" "$INDEX_FILE"; then
      log "SUCCESS" "Verificado: $check"
    else
      log "ERROR" "Falta: $check"
      log "INFO" "Buscando variaciones para debugging..."

      if [[ "$check" == "const ${entity_lower}RouterWithMiddlewares" ]]; then
        log "INFO" "Líneas con '${entity_lower}Router':"
        grep -n "${entity_lower}Router" "$INDEX_FILE" || log "INFO" "- Ninguna encontrada"
        log "INFO" "Líneas con 'RouterWithMiddlewares':"
        grep -n "RouterWithMiddlewares" "$INDEX_FILE" || log "INFO" "- Ninguna encontrada"
      fi

      all_good=false
    fi
  done

  if [[ "$all_good" == true ]]; then
    log "SUCCESS" "Todas las verificaciones pasaron correctamente."
  else
    log "WARN" "Algunas verificaciones fallaron."
    echo ""
    log "INFO" "Últimas 10 líneas del archivo para debugging:"
    tail -10 "$INDEX_FILE"
    echo ""
    return 1
  fi
}

main() {
  log "INFO" "📝 Actualizando index.js para la entidad: $entity"

  validate_environment
  initialize_variables

  cp "$INDEX_FILE" "$INDEX_FILE.backup"
  log "INFO" "Backup creado: $INDEX_FILE.backup"

  setup_imports
  setup_router_wrapper
  setup_server_route

  if verify_updates; then
    rm "$INDEX_FILE.backup"
    log "SUCCESS" "index.js actualizado correctamente para '$entity'"
    log "INFO" "Backup eliminado (actualización exitosa)"
  else
    log "WARN" "Hubo problemas en la verificación. Backup conservado."
    exit 1
  fi
}

show_help() {
  cat <<EOF
Uso: $0

Este script actualiza el archivo src/index.js para incluir las rutas
de una nueva entidad.

Variables requeridas:
  entity    - Nombre de la entidad (ej: "user", "product")

Ejemplo:
  entity="user" $0

El script realiza:
1. Agrega los imports necesarios
2. Configura el router con middlewares
3. Añade la ruta al servidor
4. Verifica que todo se haya aplicado correctamente

EOF
}

if [[ "${1:-}" == "--help" || "${1:-}" == "-h" ]]; then
  show_help
  exit 0
fi

if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
  main "$@"
fi

if [[ -n "${entity:-}" ]]; then
  main "$@"
fi
