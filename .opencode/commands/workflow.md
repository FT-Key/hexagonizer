---
description: Ejecuta el flujo multi-agente Quality Gate Loop: setup, plan, implement, quality gates (loop), finalize, git
agent: build
---

# Workflow Multi-Agente (Quality Gate Loop)

Ejecuta el proceso completo para resolver una historia de usuario siguiendo el ciclo: setup → plan → implement → quality gates (loop hasta pasar) → finalize → git.

## Uso
/workflow <descripcion de la historia de usuario>

## Proceso
1. Lee AGENTS.md para las reglas completas del workflow
2. Sigue las fases P0 a P5 definidas en AGENTS.md
3. Cada fase delega al subagente correspondiente via Task tool
4. **Fase 3 es un LOOP**: si algun quality gate falla, vuelve a Fase 2 (implement)
5. Los gates se ejecutan EN PARALELO cuando sea posible
6. Al finalizar, presenta un resumen al usuario con:
   - Archivos creados/modificados
   - Resultados de cada quality gate
   - Estado final

## Estructura de archivos
- `.opencode/workflow/STATE.md` — Indice liviano del estado actual
- `.opencode/workflow/history/US-XXX.md` — Detalle completo de cada US
