#!/bin/bash

INDEX_FILE="src/index.js"

if [ ! -f "$INDEX_FILE" ]; then
  echo "⚠️  No se encontró index.js en src/"
  exit 0
fi

entity_lower=$(echo "$entity" | tr '[:upper:]' '[:lower:]')
entity_pascal=$(echo "$entity" | sed -E 's/(^|-)([a-z])/\U\2/g')

# Función para insertar línea con sed escapando caracteres especiales
insert_after_line() {
  local file="$1"
  local pattern="$2"
  local line_to_insert="$3"
  # Escapar / y & para sed
  local escaped_line
  escaped_line=$(printf '%s\n' "$line_to_insert" | sed -e 's/[\/&]/\\&/g')
  # Usar delimitador | para evitar conflictos con /
  sed -i "\|$pattern|a $escaped_line" "$file"
}

# === IMPORTS ===

# 1. Import de routes
route_import_line="import ${entity_lower}Routes from './interfaces/http/${entity_lower}/${entity_lower}.routes.js';"
if grep -Fq "$route_import_line" "$INDEX_FILE"; then
  echo "🔹 Import de routes ya existe, no se agrega."
else
  insert_after_line "$INDEX_FILE" "import publicRoutes from" "$route_import_line"
fi

# 1.5 Import de createQueryMiddlewares
query_middleware_import="import { createQueryMiddlewares } from './interfaces/http/middlewares/query.middlewares.js';"
if grep -Fq "$query_middleware_import" "$INDEX_FILE"; then
  echo "🔹 Import de createQueryMiddlewares ya existe, no se agrega."
else
  insert_after_line "$INDEX_FILE" "^import " "$query_middleware_import"
fi

# 2. Import de query config
config_import_line="import { ${entity_lower}QueryConfig } from './interfaces/http/${entity_lower}/query-${entity_lower}-config.js';"
if grep -Fq "$config_import_line" "$INDEX_FILE"; then
  echo "🔹 Import de query config ya existe, no se agrega."
else
  insert_after_line "$INDEX_FILE" "query\.middlewares\.js';" "$config_import_line"
fi

# === ROUTER WRAPPER ===

router_const="const ${entity_lower}RouterWithMiddlewares"
if ! grep -q "$router_const" "$INDEX_FILE"; then
  tmp=$(mktemp)
  awk -v entity_lower="$entity_lower" '
    BEGIN {
      decl = "const " entity_lower "RouterWithMiddlewares = wrapRouterWithFlexibleMiddlewares(" entity_lower "Routes, {\
\n  globalMiddlewares: createQueryMiddlewares(" entity_lower "QueryConfig),\
\n  excludePathsByMiddleware,\
\n  routeMiddlewares,\
\n});\
\n"
      added = 0
    }
    {
      if (!added && /^const publicRouter = /) {
        print decl
        added = 1
      }
      print
    }
  ' "$INDEX_FILE" >"$tmp" && mv "$tmp" "$INDEX_FILE"
fi

# === RUTAS EN SERVER ===
route_entry="    { path: '/${entity_lower}', handler: ${entity_lower}RouterWithMiddlewares },"

if grep -Fq "$route_entry" "$INDEX_FILE"; then
  echo "🔹 Ruta ya existe en $INDEX_FILE, no se agrega."
else
  tmpfile=$(mktemp)
  awk -v route="$route_entry" '
    BEGIN { insideRoutesBlock=0; inserted=0 }
    {
      # Detectar inicio bloque routes: [
      if ($0 ~ /routes:\s*\[/) {
        insideRoutesBlock=1
      }
      # Insertar la ruta justo antes de la línea con cierre del array ]
      if (insideRoutesBlock && $0 ~ /^\s*\]/ && inserted == 0) {
        print route
        inserted=1
      }
      print $0
      # Detectar fin del bloque
      if (insideRoutesBlock && $0 ~ /^\s*\]/) {
        insideRoutesBlock=0
      }
    }
    END {
      if (inserted == 0) {
        # Si no se insertó la ruta porque no encontró routes: [
        # Append al final
        print route > "/dev/stderr"
      }
    }
  ' "$INDEX_FILE" >"$tmpfile"

  # Si awk mandó ruta para append (en stderr), agregarla al final
  if grep -q "^    { path: '/" "$tmpfile"; then
    mv "$tmpfile" "$INDEX_FILE"
  else
    echo "$route_entry" >>"$INDEX_FILE"
    rm "$tmpfile"
  fi

fi

echo "✅ index.js actualizado con rutas y middlewares para '$entity'"
