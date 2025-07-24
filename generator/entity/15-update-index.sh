#!/bin/bash

INDEX_FILE="src/index.js"
if [ ! -f "$INDEX_FILE" ]; then
  echo "⚠️  No se encontró index.js en src/"
  exit 0
fi

entity_lower=$(echo "$entity" | tr '[:upper:]' '[:lower:]')
entity_pascal=$(echo "$entity" | sed -E 's/(^|-)([a-z])/\U\2/g')

# Utilidad para insertar si no existe
add_unique_line() {
  local line="$1"
  grep -Fqx "$line" "$INDEX_FILE" || echo "$line" >>"$INDEX_FILE"
}

# === 1. IMPORTS ===
declare -A IMPORTS=(
  ["routes"]="import ${entity_lower}Routes from './interfaces/http/${entity_lower}/${entity_lower}.routes.js';"
  ["queryConfig"]="import { ${entity_lower}QueryConfig } from './interfaces/http/${entity_lower}/query-${entity_lower}-config.js';"
  ["middleware"]="import { createQueryMiddlewares } from './interfaces/http/middlewares/query.middlewares.js';"
)

for key in "${!IMPORTS[@]}"; do
  line="${IMPORTS[$key]}"
  if grep -Fq "$line" "$INDEX_FILE"; then
    echo "🔹 Import '$key' ya existe."
  else
    # Insertar luego de la última import
    awk -v newline="$line" '
      BEGIN { added=0 }
      /^import / {
        last_import=NR
      }
      { lines[NR]=$0 }
      END {
        for (i=1; i<=NR; i++) {
          print lines[i]
          if (i == last_import) print newline
        }
      }
    ' "$INDEX_FILE" >"$INDEX_FILE.tmp" && mv "$INDEX_FILE.tmp" "$INDEX_FILE"
    echo "✅ Import '$key' agregado"
  fi
done

# === 2. Router Wrapper ===
router_wrapper_block="const ${entity_lower}RouterWithMiddlewares = wrapRouterWithFlexibleMiddlewares(${entity_lower}Routes, {
  globalMiddlewares: createQueryMiddlewares(${entity_lower}QueryConfig),
  excludePathsByMiddleware,
  routeMiddlewares,
});"

if grep -Fq "const ${entity_lower}RouterWithMiddlewares" "$INDEX_FILE"; then
  echo "🔹 Bloque del router ya existe."
else
  awk -v block="$router_wrapper_block" '
    BEGIN { added=0 }
    /^const publicRouter = / && !added {
      print block
      print ""
      added=1
    }
    { print }
  ' "$INDEX_FILE" >"$INDEX_FILE.tmp" && mv "$INDEX_FILE.tmp" "$INDEX_FILE"
  echo "✅ Bloque del router agregado"
fi

# === 3. Ruta en server ===
route_line="    { path: '/${entity_lower}', handler: ${entity_lower}RouterWithMiddlewares },"
if grep -Fq "$route_line" "$INDEX_FILE"; then
  echo "🔹 Ruta ya existe en servidor."
else
  awk -v newroute="$route_line" '
    BEGIN { inRoutes=0; added=0 }
    /routes:[[:space:]]*\[/ { inRoutes=1 }
    inRoutes && /^\s*\]/ && !added {
      print newroute
      added=1
    }
    { print }
  ' "$INDEX_FILE" >"$INDEX_FILE.tmp" && mv "$INDEX_FILE.tmp" "$INDEX_FILE"
  echo "✅ Ruta agregada al servidor"
fi

echo "✅ index.js actualizado correctamente para '$entity'"
