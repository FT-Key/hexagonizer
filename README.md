# 🧱 Hexagonizer

**Hexagonizer** es una herramienta de línea de comandos (CLI) para generar proyectos Node.js con **arquitectura hexagonal limpia**, organizados en capas como dominio, infraestructura, interfaces HTTP, casos de uso y pruebas automatizadas.

> 🚧 **Work in Progress (WIP)** – El proyecto está en desarrollo activo. Algunas funciones están completas y otras en construcción.

---

## 📦 Instalación

```bash
npm install -g hexagonizer
```

Esto instalará el comando global:

```bash
hexagonizer
```

---

## 🚀 ¿Qué hace Hexagonizer?

- ⚙️ **Inicializa un proyecto base** con:

  - Estructura hexagonal lista para trabajar
  - Servidor Express preconfigurado
  - Middlewares comunes (`auth`, `checkRole`, `rateLimiter`, etc.)
  - Rutas y controladores conectados automáticamente
  - Frontend simple (`index.html`) de bienvenida

- 🧱 **Genera entidades completas**, listas para usar:

  - Clase de dominio con campos base (`id`, `active`, `createdAt`, etc.)
  - Repositorio In-Memory
  - Casos de uso (`create`, `update`, `get`, `delete`, `deactivate`)
  - Validaciones dinámicas según los atributos
  - Pruebas unitarias completas
  - Configuración de filtros, orden y búsqueda (`queryConfig`)
  - Rutas + middlewares integrados al servidor

- 🔁 **Soporte para entidades desde JSON schema personalizado** (en desarrollo)

---

## 🧪 Cómo usar

### 1. Iniciar un nuevo proyecto

```bash
hexagonizer
```

> Luego seleccioná la opción **"Init project"** y seguí las instrucciones del asistente interactivo.

---

### 2. Generar una entidad genérica

```bash
hexagonizer
```

> Elegí **"Generate entity"** y escribí el nombre (por ejemplo `user`).

Esto creará:

```
📁 src/
  └── domain/user/User.js
  └── application/user/
  └── infrastructure/user/
  └── interfaces/http/user/
📁 tests/application/user/
```

Todo enlazado automáticamente con el servidor y middlewares.

---

### 3. (WIP) Generar entidad desde JSON

```bash
hexagonizer
```

> Luego elegí la opción **"Generate entity from JSON schema"** y proporciona el archivo.

> ⚠️ Aún está en desarrollo. Genera algunos archivos, pero puede requerir ajustes manuales.

---

## 📁 Estructura generada

```
hexagon-project/
├── src/
│   ├── domain/
│   ├── application/
│   ├── infrastructure/
│   ├── interfaces/
│   │   └── http/
│   │       ├── middlewares/
│   │       └── <entity>/
│   ├── config/
│   └── index.js
├── tests/
│   └── application/<entity>/
└── package.json
```

---

## 🔍 Estado actual

| Funcionalidad                      | Estado          |
| ---------------------------------- | --------------- |
| CLI interactivo                    | ✅ Completo     |
| Init de proyecto base              | ✅ Completo     |
| Generar entidad genérica           | ✅ Completo     |
| Validaciones dinámicas             | ✅ Completo     |
| Middlewares de consulta (`q`, etc) | ✅ Completo     |
| Tests automáticos por entidad      | ✅ Completo     |
| Generación desde JSON schema       | 🚧 Parcial      |
| Modularización vía scripts         | ✅ Completo     |
| Instalación global via npm         | ✅ Desde v1.1.0 |

---

## 📣 Contribuciones

Este proyecto está en constante evolución. Si querés ayudar, proponer ideas o reportar errores, ¡sos bienvenido!

---

## 🧾 Licencia

MIT © 2025 — Franco Toledo
