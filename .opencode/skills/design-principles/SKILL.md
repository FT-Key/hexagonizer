---
name: design-principles
description: Principios SOLID, KISS, DRY, YAGNI y reglas de diseno limpio. Usar siempre antes y durante la implementacion
license: MIT
---

## SOLID

### S — Single Responsibility
Una clase/funcion debe tener UNA sola razon para cambiar.

- Entidades: solo logica de negocio y validacion de dominio
- Use cases: solo orquestacion de flujos
- Repositorios: solo persistencia
- Controladores: solo recibir request y devolver response
- Funciones de Bash: una tarea por script/modulo

### O — Open/Closed
Abierto a extension, cerrado a modificacion.

- Usa parametros y configuracion para cambiar comportamiento
- NO modifiques funciones existentes para anadir comportamiento
- Ej: nuevo tipo de repositorio → nueva clase que implementa la interfaz

### L — Liskov Substitution
Las subclases deben poder reemplazar a sus padres sin alterar el programa.

- NO sobrescribas comportamiento base de forma inesperada
- Las implementaciones deben cumplir el contrato

### I — Interface Segregation
Mejor muchas interfaces especificas que una general.

- `UserRepository` (CRUD usuario) separado de `AnalyticsRepository`
- NO obligues a implementar metodos que no se usan

### D — Dependency Inversion
Depende de abstracciones, no de implementaciones concretas.

- Use cases dependen de una interfaz de repositorio (NO de la implementacion concreta)
- La inyeccion se decide en el punto de entrada (controller)

## KISS (Keep It Simple, Stupid)

- La solucion mas simple que funciona es la correcta
- No anticipes necesidades futuras (YAGNI)
- Si una funcion tiene > 30 lineas, dividela
- Prefiere funciones puras sobre clases cuando no haya estado

## DRY (Don't Repeat Yourself)

- Codigo duplicado 2+ veces → extraer a funcion/modulo
- PERO no fuerces DRY prematuramente (viola KISS)
- La abstraccion incorrecta es peor que la duplicacion

## YAGNI (You Ain't Gonna Need It)

- No anadas abstracciones "por si acaso"
- No crees interfaces hasta que necesites una segunda implementacion
- No anadas funcionalidad que no esta en los requisitos actuales

## Reglas adicionales

### Command-Query Separation (CQS)
- Metodos que modifican estado (comandos) no devuelven datos
- Metodos que consultan (queries) no modifican estado

### Fail Fast
- Valida inputs al inicio de cada funcion
- Si un parametro es invalido, lanza error inmediatamente

### Early Returns
- Evita if-else anidados profundos
- Valida y retorna temprano, el flujo feliz al final

### Bash scripting
- Usa `set -e` para fail fast en scripts
- Usa `set -u` para variables no definidas
- Siempre cita variables con comillas dobles: `"$var"`
- Prefiere `[[ ... ]]` sobre `[ ... ]` en Bash
