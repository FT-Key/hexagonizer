# Getting Started

## Instalacion

```bash
npm install -g hexagonizer
```

## Primer proyecto

```bash
# Crear y entrar al directorio
mkdir mi-app && cd mi-app

# Inicializar proyecto con arquitectura hexagonal
hexagonizer
```

Selecciona la opcion **1 - Inicializar proyecto** y el CLI creara toda la estructura.

## Agregar una entidad

Dentro del proyecto generado:

```bash
hexagonizer
```

Selecciona la opcion **2 - Generar entidad** e ingresa el nombre (ej: `Product`).
O usa la opcion **4 - Generar desde JSON** pasando un schema predefinido.

## Desarrollo

El proyecto generado incluye:

```bash
npm run dev    # Servidor con nodemon (hot reload)
npm start      # Servidor en produccion
npm test       # Ejecutar tests
```

## Ejemplo rapido: Product

```bash
# 1. Crear proyecto
mkdir tienda && cd tienda
hexagonizer   # Opcion 1

# 2. Agregar entidad Product
hexagonizer   # Opcion 2, nombre: "Product"

# 3. Iniciar servidor
hexagonizer   # Opcion 6 > opcion 2 (npm run dev)
# Servidor en http://localhost:3000

# 4. Probar API
curl http://localhost:3000/product              # GET listar
curl -X POST http://localhost:3000/product \    # POST crear
  -H "Content-Type: application/json" \
  -d '{"name":"Laptop","price":999}'
```
