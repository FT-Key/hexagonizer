# Reglas del equipo multi-agente

## Flujo de trabajo (Quality Gate Loop)

Cuando recibas una solicitud de implementacion, sigue este proceso. Es un LOOP entre implementacion y quality gates hasta que todo pase.

### Fase 0: SETUP

1. Si el usuario tiene una idea vaga o no existe .opencode/workflow/REQUIREMENTS.md:
   a. Indica al usuario que puede cambiar al agente @systems-analyst
      (presionando Tab) para definir los requisitos primero
   b. Una vez que exista .opencode/workflow/REQUIREMENTS.md, lo usaras como entrada
2. Si no existe .opencode/workflow/DESIGN_SYSTEM.md y el cambio toca UI:
   a. Indica al usuario que puede cambiar al agente @design-strategist
      (presionando Tab) para definir la vision de diseno primero
3. Si ya existe .opencode/workflow/REQUIREMENTS.md, leelo para entender el contexto
4. Lee .opencode/workflow/STATE.md (solo el indice, no los historiales previos)

### Fase 1: PLAN (si afecta a multiples archivos)

1. Si el cambio es trivial (1-2 archivos), puedes saltar esta fase
2. Escribe el plan en .opencode/workflow/STATE.md seccion ## Plan
3. Define: archivos a crear/modificar, modulos, funciones, tipos
4. Si el plan es complejo, delega a @architect via Task tool
5. NO implementes sin plan si afecta a multiples archivos

### Fase 2: IMPLEMENT

1. Lee el plan de .opencode/workflow/STATE.md si existe
2. Carga skills relevantes segun corresponda:
   - `project-structure` — siempre que toques estructura
   - `design-principles` — siempre (SOLID, KISS, DRY, YAGNI)
   - `design-patterns` — patrones de diseno
   - `error-handling` — manejo de errores
3. Para implementacion directa: hazlo tu mismo
4. Para implementacion compleja: delega a @builder via Task tool
5. **@reviewer**: Code review de los cambios

### Fase 3: QUALITY GATES (LOOP)

Ejecuta los gates EN PARALELO via Task tool cuando sea posible.

**Gate 3.1 Code Review (@reviewer)**
- Revisa calidad, bugs, buenas practicas, seguridad
- Reporta issues bloqueantes y no bloqueantes
- Verifica que se sigan las convenciones del proyecto

**Al terminar los gates:**
1. Evaluar resultados:
   - Si TODOS los gates pasaron → continuar a Fase 4
   - Si ALGUN gate fallo → **volver a Fase 2** (corregir)
   - El bucle se repite hasta que todos los gates pasen

### Fase 4: FINALIZE

1. Escribir resumen final en .opencode/workflow/STATE.md con:
   - Archivos creados/modificados
   - Decisiones tecnicas clave
   - Resultados de todos los gates

### Fase 5: GIT

1. **@git-specialist**: Crear branch, commit con conventional commits, push

---

## Como delegar a subagentes

Usa el Task tool, NO @mention:

```
Task({
  description: "Implementar modulo X",
  prompt: "Instrucciones detalladas para el subagente...",
  subagent_type: "builder"
})
```

### Tipos de subagente disponibles

| Agente | Para que |
|--------|----------|
| `architect` | Planificar arquitectura, escribir plan en .opencode/workflow/history/ |
| `builder` | Implementar codigo (Bash/JavaScript) |
| `reviewer` | Code review de cambios |
| `git-specialist` | Git/GitHub experto — solo Git, NO explora codigo |

### Agentes de dialogo (mode: all)

| Agente | Para que |
|--------|----------|
| `systems-analyst` | Analizar requisitos, escribir .opencode/workflow/REQUIREMENTS.md |
| `design-strategist` | Definir vision de diseno, escribir .opencode/workflow/DESIGN_SYSTEM.md |

### Como cargar una skill

Las skills proveen conocimiento contextual para tareas especificas:

```
skill({ name: "project-structure" })
```

Se pueden cargar multiples skills al inicio de una tarea.

## Stack del proyecto

- **CLI tool**: Bash scripting
- **Runtime**: Node.js (para utilidades JS del generador)
- **Generador de proyectos**: Bash + Node.js
- **Proyectos generados**: Node.js + Express + ESM

## Reglas generales

- NO modifiques codigo sin entenderlo primero
- El flujo es un LOOP: si los quality gates fallan, vuelve a implementar
- Cada subagente escribe SOLO en los archivos que tiene permitido
- .opencode/workflow/STATE.md debe mantenerse LIVIANO (< 50 lineas)
- Los detalles de cada US van en .opencode/workflow/history/US-XXX.md
- No leas historiales previos completos a menos que sean necesarios
- Define claramente "Definition of Done" antes de marcar como completado
