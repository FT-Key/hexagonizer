---
name: error-handling
description: Manejo de errores en proyectos Express generados por hexagonizer. Jerarquia AppError y middleware global
license: MIT
---

## Jerarquia de errores

```
Error
└── AppError (base)
    ├── DomainError        ← reglas de negocio violadas
    │   ├── InvalidEmailError
    │   ├── EntityNotFoundError
    │   └── ValidationError
    ├── ApplicationError   ← errores de casos de uso
    │   ├── UnauthorizedError
    │   └── ForbiddenError
    └── InfrastructureError ← errores tecnicos
        ├── DatabaseError
        └── ExternalServiceError
```

## Implementacion

```javascript
// src/shared/errors/AppError.js
export class AppError extends Error {
  constructor(message, code, httpStatus = 500, details = null) {
    super(message);
    this.name = this.constructor.name;
    this.code = code;
    this.httpStatus = httpStatus;
    this.details = details;
  }

  toJSON() {
    return {
      code: this.code,
      message: this.message,
      details: this.details,
      ...(process.env.NODE_ENV === 'development' && { stack: this.stack }),
    };
  }
}

// src/shared/errors/DomainError.js
export class DomainError extends AppError {
  constructor(message, code, details) {
    super(message, code, 400, details);
  }
}
```

## Global Error Handler (Express)

```javascript
// src/interfaces/http/middlewares/error-handler.js
import { AppError } from '../../../shared/errors/AppError.js';

export function errorHandler(err, req, res, next) {
  if (err instanceof AppError) {
    return res.status(err.httpStatus).json({
      success: false,
      error: err.toJSON(),
    });
  }

  console.error('Unhandled error:', err);
  return res.status(500).json({
    success: false,
    error: {
      code: 'INTERNAL_ERROR',
      message: 'An unexpected error occurred',
    },
  });
}

// En el server:
// app.use(errorHandler);
```

## Uso en use cases

```javascript
export class GetUser {
  constructor(repository) {
    this.repository = repository;
  }

  async execute(id) {
    if (!id) throw new DomainError('User id is required', 'VALIDATION_ERROR');

    const user = await this.repository.findById(id);
    if (!user) throw new DomainError('User not found', 'NOT_FOUND', { id });

    return user;
  }
}
```

## Patron para controladores Express

```javascript
export const getUserController = async (req, res, next) => {
  try {
    const useCase = new GetUser(repository);
    const user = await useCase.execute(req.params.id);
    res.json(user);
  } catch (error) {
    next(error); // Delega al errorHandler global
  }
};
```

## Reglas

- DomainError para reglas de negocio violadas (400)
- ApplicationError para errores de autorizacion (401/403)
- InfrastructureError para fallos tecnicos (500)
- Siempre usa `next(error)` en controladores para delegar al error handler global
- No expongas errores internos al cliente en produccion
- Usa try/catch en todos los async handlers
