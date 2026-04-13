---
description: Revisa si los cambios actuales están bien agrupados para commit
agent: plan
model: "openrouter/moonshotai/kimi-k2:free"
---

Quiero revisar si mis cambios están bien agrupados antes de commitear.

Rama actual:
!`git branch --show-current`

Estado:
!`git status --short`

Archivos staged:
!`git diff --cached --name-only`

Archivos unstaged:
!`git diff --name-only`

Resumen staged:
!`git diff --cached --stat`

Resumen unstaged:
!`git diff --stat`

Analiza esto y responde con:

1. si hay una sola intención o varias mezcladas,
2. qué grupos de commit propones,
3. qué archivos meterías en cada grupo,
4. qué archivos sacarías de este commit,
5. 2 o 3 mensajes de commit precisos.

Sé estricto con la separación lógica de cambios.
