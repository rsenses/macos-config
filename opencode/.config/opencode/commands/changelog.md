---
description: Crea o actualiza una entrada de changelog para la tarea actual
agent: build
model: opencode/mimo-v2-flash-free
---

Necesito crear o actualizar la entrada de changelog de esta tarea.

Rama actual:
!`git branch --show-current`

Estado:
!`git status --short`

Cambios staged:
!`git diff --cached --stat`

Cambios unstaged:
!`git diff --stat`

Archivos existentes en changelogs:
!`bash -lc 'ls -1 changelogs 2>/dev/null | tail -20 || true'`

Haz lo siguiente:

1. identifica el cambio funcional o técnico principal,
2. el formato está basado en [Keep a Changelog](https://keepachangelog.com/es-ES/1.1.0/), y este proyecto sigue [SemVer](https://semver.org/lang/es/).
3. actualiza el archivo `CHANGELOG.md` con fecha actual,
4. al final propone también un commit message Conventional Commit apropiado.
