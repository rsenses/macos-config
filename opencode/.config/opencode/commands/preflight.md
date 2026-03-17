---
description: Revisa rama y estado antes de empezar una tarea
agent: plan
model: opencode/mimo-v2-flash-free
---

Estoy empezando esta tarea.

Rama actual:
!`git branch --show-current`

Estado:
!`git status --short`

Últimos commits:
!`git log --oneline -8`

Analiza el contexto y responde con:

1. si la rama actual es adecuada para trabajar,
2. si el árbol está limpio o arrastro cambios previos,
3. si detectas mezcla de intenciones,
4. un nombre de rama recomendado para esta tarea,
5. un plan corto de implementación.

Si estoy en una rama protegida o el árbol está sucio con cambios no relacionados, dilo claramente al inicio.
