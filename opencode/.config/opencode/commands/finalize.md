---
description: Ejecuta fix y test y deja la tarea lista para revisión final
agent: build
model: "opencode/minimax-m2.5-free"
---

Voy a cerrar esta tarea. Ejecuta el flujo final del proyecto y deja todo listo para revisión.

Rama actual:
!`git branch --show-current`

Estado inicial:
!`git status --short`

Resultado de composer fix:
!`bash -lc 'composer fix || true'`

Estado tras composer fix:
!`git status --short`

Archivos modificados tras composer fix:
!`git diff --name-only`

Resultado de composer test:
!`bash -lc 'composer test || true'`

Estado final:
!`git status --short`

Estado de CHANGELOG.md:
!`bash -lc 'test -f CHANGELOG.md && echo "CHANGELOG.md presente" || echo "CHANGELOG.md ausente"'`

Diff actual de CHANGELOG.md:
!`git diff -- CHANGELOG.md`

Actúa así:

1. ejecuta `composer fix` y revisa si ha modificado archivos,
2. ejecuta `composer test` y resume errores o fallos si los hay,
3. da prioridad absoluta a cualquier problema que pueda romper CI/CD o impedir el deploy,
4. comprueba después si `CHANGELOG.md` necesita actualización en función de los cambios realizados,
5. si falta una entrada visible para usuario y la convención del proyecto indica que debe existir, añade el contenido adecuado en formato Keep a Changelog y alineado con SemVer,
6. no hagas commit automáticamente.

Prioriza:

1. errores de `composer fix` y cambios automáticos que requieren revisión,
2. fallos de `composer test`,
3. estado final del árbol de trabajo,
4. necesidad de actualizar `CHANGELOG.md`,
5. riesgos antes de pasar a revisión final.
6. propone el tipo y scope de Conventional Commit más adecuados,
7. recomienda un mensaje final en formato `type(scope): summary`,

Salida final:

- checks ejecutados
- archivos modificados por fix
- estado de tests
- estado final del árbol
- estado de changelog
- problemas bloqueantes
- problemas no bloqueantes
- veredicto final: `listo para ship` o `no listo para ship`
- riesgos antes de revisión final
- sugerencia de Conventional Commit
