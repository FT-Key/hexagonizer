#!/bin/bash

INDEX_FILE="src/index.js"

if [ ! -f "$INDEX_FILE" ]; then
  echo "⚠️  No se encontró index.js en src/"
  exit 0
fi

entity_lower=$(echo "$entity" | tr '[:upper:]' '[:lower:]')
entity_pascal=$(echo "$entity" | sed -E 's/(^|-)([a-z])/\U\2/g')

# === IMPORTS ===

# 1. Import de routes
route_import_line="import ${entity_lower}Routes from './interfaces/http/${entity_lower}/${entity_lower}.routes.js';"
if ! grep -Fq "$route_import_line" "$INDEX_FILE"; then
  # Insert justo antes de publicRoutes para mantener orden
  sed -i "/import publicRoutes from/a $route_import_line" "$INDEX_FILE"
fi

# 2. Import de query config
config_import_line="import { ${entity_lower}QueryConfig } from './interfaces/http/${entity_lower}/query-${entity_lower}-config.js';"
if ! grep -Fq "$config_import_line" "$INDEX_FILE"; then
  # Buscar específicamente query.middlewares.js (más confiable)
  sed -i "/query\.middlewares\.js';/a $config_import_line" "$INDEX_FILE"
fi

# === ROUTER WRAPPER ===

# 3. Definición de router con middlewares
router_const="const ${entity_lower}RouterWithMiddlewares"
if ! grep -q "$router_const" "$INDEX_FILE"; then
  tmp=$(mktemp)
  awk -v declaration="const ${entity_lower}RouterWithMiddlewares = wrapRouterWithFlexibleMiddlewares(${entity_lower}Routes, {\n  globalMiddlewares: createQueryMiddlewares(${entity_lower}QueryConfig),\n  excludePathsByMiddleware,\n  routeMiddlewares,\n});\n" '
    BEGIN { added = 0 }
    {
      if (!added && /^const publicRouter = /) {
        printf("%s\n", declaration)
        added = 1
      }
      print
    }
  ' "$INDEX_FILE" >"$tmp" && mv "$tmp" "$INDEX_FILE"
fi

# === RUTAS EN SERVER ===

# 4. Agregar la ruta al array routes[]
route_entry="    { path: '/${entity_lower}', handler: ${entity_lower}RouterWithMiddlewares },"
if ! grep -Fq "$route_entry" "$INDEX_FILE"; then
  sed -i "/routes: \[/a $route_entry" "$INDEX_FILE"
fi

echo "✅ index.js actualizado con rutas y middlewares para '$entity'"
