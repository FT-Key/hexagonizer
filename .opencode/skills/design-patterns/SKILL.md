---
name: design-patterns
description: Catalogo de patrones de diseno aprobados para el proyecto. No usar patrones donde una funcion simple baste
license: MIT
---

## Factory Method

Creacion de objetos complejos o con logica condicional.

```javascript
// src/domain/user/user-factory.js
export class UserFactory {
  static create(data) {
    const id = crypto.randomUUID();
    const createdAt = new Date();
    return new User(
      id,
      data.name,
      data.email,
      data.role || 'customer',
      createdAt,
      createdAt
    );
  }

  static fromPersistence(row) {
    return new User(
      row.id,
      row.name,
      row.email,
      row.role,
      row.createdAt,
      row.updatedAt
    );
  }
}
```

## Repository

Abstraccion sobre la capa de datos. Separa la logica de negocio de la persistencia.

```javascript
// src/infrastructure/user/in-memory-user-repository.js
export class InMemoryUserRepository {
  constructor() {
    this.items = [];
  }

  async save(item) {
    const index = this.items.findIndex(i => i.id === item.id);
    if (index === -1) {
      this.items.push(item);
    } else {
      this.items[index] = item;
    }
    return item;
  }

  async findById(id) {
    return this.items.find(i => i.id === id) || null;
  }
}
```

## Use Case (Command Pattern)

Cada operacion de negocio es un objeto con un metodo execute().

```javascript
// src/application/user/use-cases/create-user.js
export class CreateUser {
  constructor(repository) {
    this.repository = repository;
  }

  async execute(data) {
    const entity = UserFactory.create(data);
    return this.repository.save(entity);
  }
}
```

## Value Object

Objeto inmutable que encapsula un valor con validacion.

```javascript
// src/domain/value-objects/Email.js
export class Email {
  constructor(value) {
    const emailRegex = /^[^\s@]+@[^\s@]+\.[^\s@]+$/;
    if (!emailRegex.test(value)) {
      throw new Error(`Invalid email: ${value}`);
    }
    this._value = value.toLowerCase();
    Object.freeze(this);
  }

  get value() { return this._value; }

  equals(other) {
    return this._value === other.value;
  }
}

// Uso
const email = new Email('user@example.com');
```

## Mapper

Convierte entre formatos de datos sin acoplar capas.

```javascript
// src/infrastructure/user/mappers/user-mapper.js
export function userToPersistence(user) {
  return {
    id: user.id,
    name: user.name,
    email: user.email,
    created_at: user.createdAt,
    updated_at: user.updatedAt,
  };
}

export function userFromPersistence(row) {
  return new User(
    row.id, row.name, row.email,
    row.role, row.createdAt, row.updatedAt
  );
}
```

## Reglas de uso

- Factory para creacion compleja o condicional
- Repository siempre para acceso a datos
- Mapper para cada conversion entre capas
- Use Case para cada operacion de negocio
- Value Object para tipos primitivos con validacion (Email, Phone, DNI, RUT)
- NO uses patrones donde una funcion simple baste (KISS)
