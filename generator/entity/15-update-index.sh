#!/bin/bash
# update-index.sh - Actualiza el archivo index.js con rutas de entidad
set -e

source "$PROJECT_ROOT/generator/common/logging.sh"

readonly INDEX_FILE="src/index.js"

validate_environment() {
  if [[ ! -f "$INDEX_FILE" ]]; then
    log "WARN" "File '$INDEX_FILE' not found. Nothing to update."
    exit 0
  fi

  if [[ -z "${entity:-}" ]]; then
    log "ERROR" "Variable 'entity' is not defined. Aborting."
    exit 1
  fi
}

initialize_variables() {
  entity_lower=$(echo "$entity" | tr '[:upper:]' '[:lower:]')
  entity_pascal=$(echo "$entity" | sed -E 's/(^|-)([a-z])/\U\2/g')
  log "INFO" "Variables initialized: entity_lower='$entity_lower', entity_pascal='$entity_pascal'"
}

add_unique_line() {
  local line="$1"
  if grep -Fqx "$line" "$INDEX_FILE"; then
    log "INFO" "Line already exists, skipping: $line"
  else
    echo "$line" >>"$INDEX_FILE"
    log "SUCCESS" "Line added: $line"
  fi
}

apply_awk_transformation() {
  local awk_script="$1"
  local success_message="$2"

  awk "$awk_script" "$INDEX_FILE" >"$INDEX_FILE.tmp" && mv "$INDEX_FILE.tmp" "$INDEX_FILE"
  log "SUCCESS" "$success_message"
}

setup_imports() {
  log "INFO" "Setting up imports..."

  declare -A imports=(
    ["routes"]="import ${entity_lower}Routes from './interfaces/http/${entity_lower}/${entity_lower}.routes.js';"
    ["queryConfig"]="import { ${entity_lower}QueryConfig } from './interfaces/http/${entity_lower}/query-${entity_lower}-config.js';"
    ["middleware"]="import { createQueryMiddlewares } from './interfaces/http/middlewares/query.middlewares.js';"
  )

  for key in "${!imports[@]}"; do
    local line="${imports[$key]}"
    if grep -Fq "$line" "$INDEX_FILE"; then
      log "INFO" "Import '$key' already exists."
    else
      add_import_after_last_import "$line"
      log "SUCCESS" "Import '$key' added."
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
  " "Import added after last import statement"
}

setup_router_wrapper() {
  log "INFO" "Setting up router wrapper..."

  local router_wrapper_block="const ${entity_lower}RouterWithMiddlewares = wrapRouterWithFlexibleMiddlewares(${entity_lower}Routes, {
  globalMiddlewares: createQueryMiddlewares(${entity_lower}QueryConfig),
  excludePathsByMiddleware,
  routeMiddlewares,
});"

  if grep -Fq "const ${entity_lower}RouterWithMiddlewares" "$INDEX_FILE"; then
    log "INFO" "Router block already exists, skipping insertion."
    return 0
  fi

  log "INFO" "Current state of '$INDEX_FILE':"
  log "INFO" "- Total lines: $(wc -l <"$INDEX_FILE")"
  log "INFO" "- const declarations: $(grep -c '^const' "$INDEX_FILE" || echo '0')"
  log "INFO" "- Lines with 'router': $(grep -c -i 'router' "$INDEX_FILE" || echo '0')"

  if add_router_wrapper_block "$router_wrapper_block"; then
    log "SUCCESS" "Router wrapper configured successfully."
  else
    log "ERROR" "Router wrapper configuration failed."
    log "INFO" "Applying fallback strategy: inserting at end of file..."

    echo "" >>"$INDEX_FILE"
    echo "$router_wrapper_block" >>"$INDEX_FILE"
    echo "" >>"$INDEX_FILE"

    if grep -q "const ${entity_lower}RouterWithMiddlewares" "$INDEX_FILE"; then
      log "SUCCESS" "Router inserted at end of file as fallback."
    else
      log "ERROR" "Error: Router insertion failed completely."
      return 1
    fi
  fi
}

add_router_wrapper_block() {
  local block="$1"
  log "INFO" "Attempting router wrapper insertion..."
  log "INFO" "Block to insert:"

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
      log "SUCCESS" "Pattern found: $pattern"

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
        log "SUCCESS" "Router inserted using pattern: $pattern"
        break
      else
        rm -f "$INDEX_FILE.tmp"
      fi
    fi
  done

  if [[ "$inserted" == false ]]; then
    log "WARN" "No specific patterns found, inserting after last const declaration..."

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
    log "SUCCESS" "Router inserted after last const declaration."
  fi

  if grep -q "const ${entity_lower}RouterWithMiddlewares" "$INDEX_FILE"; then
    log "SUCCESS" "Verification: router wrapper inserted correctly."
  else
    log "ERROR" "Error: router wrapper was not inserted correctly."
    return 1
  fi
}

setup_server_route() {
  log "INFO" "Setting up server route..."

  local route_line="    { path: '/${entity_lower}', handler: ${entity_lower}RouterWithMiddlewares },"

  if grep -Fq "$route_line" "$INDEX_FILE"; then
    log "INFO" "Route already exists in server, not adding."
  else
    add_server_route "$route_line"
    log "SUCCESS" "Route added to server."
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
  " "Route added to server routes array"
}

verify_updates() {
  log "INFO" "Verifying updates..."

  local checks=(
    "import ${entity_lower}Routes"
    "import { ${entity_lower}QueryConfig }"
    "const ${entity_lower}RouterWithMiddlewares"
    "path: '/${entity_lower}'"
  )

  local all_good=true

  for check in "${checks[@]}"; do
    if grep -q "$check" "$INDEX_FILE"; then
      log "SUCCESS" "Verified: $check"
    else
      log "ERROR" "Missing: $check"
      log "INFO" "Searching for variations for debugging..."

      if [[ "$check" == "const ${entity_lower}RouterWithMiddlewares" ]]; then
        log "INFO" "Lines with '${entity_lower}Router':"
        grep -n "${entity_lower}Router" "$INDEX_FILE" || log "INFO" "- None found"
        log "INFO" "Lines with 'RouterWithMiddlewares':"
        grep -n "RouterWithMiddlewares" "$INDEX_FILE" || log "INFO" "- None found"
      fi

      all_good=false
    fi
  done

  if [[ "$all_good" == true ]]; then
    log "SUCCESS" "All verifications passed successfully."
  else
    log "WARN" "Some verifications failed."
    echo ""
    log "INFO" "Last 10 lines for debugging:"
    tail -10 "$INDEX_FILE"
    echo ""
    return 1
  fi
}

main() {
  log "INFO" "📝 Updating index.js for entity: $entity"

  validate_environment
  initialize_variables

  cp "$INDEX_FILE" "$INDEX_FILE.backup"
  log "INFO" "Backup created: $INDEX_FILE.backup"

  setup_imports
  setup_router_wrapper
  setup_server_route

  if verify_updates; then
    rm "$INDEX_FILE.backup"
    log "SUCCESS" "index.js updated successfully for '$entity'"
    log "INFO" "Backup deleted (update successful)"
  else
    log "WARN" "Verification had issues. Backup preserved."
    exit 1
  fi
}

show_help() {
  cat <<EOF
Usage: $0

This script updates the src/index.js file to include the routes
for a new entity.

Required variables:
  entity    - Entity name (e.g. "user", "product")

Example:
  entity="user" $0

The script performs:
1. Adds the necessary imports
2. Configures the router with middlewares
3. Adds the route to the server
4. Verifies everything was applied correctly

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
