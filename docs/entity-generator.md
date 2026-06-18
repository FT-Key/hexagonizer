# Entity Generator

`hexagonizer entity` genera una entidad completa con dominio, casos de uso, API REST y tests. El generador recorre **15 modulos** en pipeline.

## Estructura generada por entidad

Tomando `Product` como ejemplo:

```
src/
├── domain/
│   └── product/
│       ├── product.js               # Clase de dominio con getters/setters
│       ├── product-factory.js       # Factory (create, createMany, createDefault)
│       ├── product-validation.js    # Validacion de campos
│       ├── product-constants.js     # Constantes, enums, config
│       └── mocks.js                 # Datos de prueba
├── application/
│   └── product/
│       ├── use-cases/
│       │   ├── create-product.js    # CreateProduct
│       │   ├── get-product.js       # GetProduct
│       │   ├── update-product.js    # UpdateProduct
│       │   ├── delete-product.js    # DeleteProduct
│       │   ├── deactivate-product.js # DeactivateProduct
│       │   └── list-product.js      # ListProducts (con paginacion)
│       └── services/
│           ├── get-active-product.js
│           ├── get-inactive-product.js
│           └── count-product.js
├── infrastructure/
│   └── product/
│       ├── in-memory-product-repository.js  # Repositorio en memoria
│       └── database-product-repository.js   # Esqueleto para BD real
└── interfaces/
    └── http/
        └── product/
            ├── product.controller.js  # Controladores Express
            ├── product.routes.js      # Router CRUD
            └── query-product-config.js # Config de filtros/busqueda/orden
tests/
└── application/
    └── product/
        ├── create-product.test.js
        ├── get-product.test.js
        ├── update-product.test.js
        ├── delete-product.test.js
        └── deactivate-product.test.js
```

## Pipeline de generacion

| Modulo | Que crea |
|--------|----------|
| `03-generate-domain.sh` | Clase de dominio con constructor, getters/setters, `toJSON()`, `activate()`/`deactivate()` |
| `04-generate-validation.sh` | Funcion `validateProduct(data)` con validacion de tipos, required, min/max, email, enum |
| `05-generate-factory.sh` | `ProductFactory.create(data)`, `createMany()`, `createDefault()` |
| `06-generate-constants.sh` | Constantes (`DEFAULT_ACTIVE`, `PRODUCT_CONFIG`), enums, y mocks con datos de prueba |
| `07-generate-repository.sh` | `InMemoryProductRepository` (funcional) y `DatabaseProductRepository` (esqueleto) |
| `08-generate-usecases.sh` | 6 casos de uso CRUD + list con paginacion (`{ data, meta }`) |
| `09-generate-services.sh` | Filtros por estado activo/inactivo, contadores con stats |
| `10-generate-controller.sh` | Controladores Express que instancian use cases y responden JSON |
| `11-generate-routes.sh` | Router con `POST /`, `GET /`, `GET /:id`, `PUT /:id`, `DELETE /:id`, `PATCH /:id/deactivate` |
| `12-generate-query-entity-config.sh` | Config de campos buscables, ordenables y filtrables |
| `14-generate-tests.sh` | 5 tests con `assert` nativo de Node.js |
| `15-update-index.sh` | Parchea `src/index.js` registrando la nueva ruta |

## Formato del schema JSON

```json
{
  "name": "Product",
  "fields": [
    { "name": "name", "required": true },
    { "name": "price", "type": "number", "default": 0 },
    { "name": "email", "type": "string", "format": "email" },
    { "name": "category", "enum": ["electronics", "clothing"] },
    { "name": "password", "sensitive": true }
  ],
  "methods": [
    { "name": "decreaseStock", "params": ["qty"], "body": "this._stock -= qty;" }
  ]
}
```

### Campos base automaticos

Siempre se agregan (aunque no esten en el schema): `id`, `active`, `createdAt`, `updatedAt`, `deletedAt`, `ownedBy`.

### Flags del schema

| Flag | Default | Efecto |
|------|---------|--------|
| `timestamps` | true | Agrega createdAt, updatedAt |
| `softDelete` | true | Agrega deletedAt |
| `ownership` | true | Agrega ownedBy, createdBy, updatedBy |

## Convenciones de nombres

| Contexto | Convencion | Ejemplo |
|----------|------------|---------|
| Variable Bash | snake_case | `entity`, `EntityPascal` |
| Clase JS | PascalCase | `CreateProduct`, `InMemoryProductRepository` |
| Archivo JS | kebab-case | `in-memory-product-repository.js` |
| Ruta API | singular | `/product` |
| Tabla BD | plural + 's' | `products` |
| Metodo de repositorio | camelCase | `findById`, `save`, `deleteById` |

## Tests

- Framework: `assert` nativo de Node.js
- 5 tests por entidad: create, get, update, delete, deactivate
- Cada test es un async IIFE auto-ejecutable
- Usan `InMemoryRepository` directamente
- Se ejecutan con: `npm test` o directamente `node tests/application/product/create-product.test.js`
