---
description: Ejecuta fix y test y deja la tarea lista para commit
agent: build
model: opencode/mimo-v2-flash-free
---

Voy a cerrar esta tarea. Ejecuta el flujo final del proyecto y deja todo listo para revisión de commit.

Rama actual:
!`git branch --show-current`

Estado inicial:
!`git status --short`

Resultado de composer fix:
!`bash -lc 'composer fix || true'`

Estado tras composer fix:
!`git status --short`

Resultado de composer test:
!`bash -lc 'composer test || true'`

Estado final:
!`git status --short`

Archivos changelog actuales:
!`bash -lc 'ls -1 changelogs 2>/dev/null | tail -20 || true'`

Actúa así:

1. analiza si `composer fix` ha modificado archivos,
2. revisa si `composer test` ha pasado,
3. comprueba si existe una entrada de changelog adecuada en `changelogs/`,
4. si no existe, créala siguiendo las convenciones del proyecto,
5. no hagas commit automáticamente,
6. al final entrega:
   - resumen de cambios,
   - changelog creado o actualizado,
   - problemas pendientes,
   - riesgos,
   - y un mensaje de commit en formato Conventional Commit.
