---
description: Revisión final antes de commit o PR
agent: reviewer
model: "opencode/minimax-m2.5-free"
---

Estoy a punto de commitear estos cambios. Haz una revisión final del diff staged y dime si está listo para enviar.

Rama actual:
!`git branch --show-current`

Estado:
!`git status --short`

Archivos staged:
!`git diff --cached --name-only`

Resumen del diff staged:
!`git diff --cached --stat`

Diff staged completo:
!`git diff --cached`

Estado de CHANGELOG.md:
!`bash -lc 'test -f CHANGELOG.md && echo "CHANGELOG.md presente" || echo "CHANGELOG.md ausente"'`

Diff staged de CHANGELOG.md:
!`git diff --cached -- CHANGELOG.md`

Diff no staged de CHANGELOG.md:
!`git diff -- CHANGELOG.md`

Actúa así:

1. revisa si el commit está bien acotado,
2. comprueba si `CHANGELOG.md` falta o está incompleto para este cambio,
3. valora si la entrada del changelog sigue razonablemente el formato Keep a Changelog,
4. estima qué impacto SemVer sugiere el cambio (`patch`, `minor` o `major`),
5. señala riesgos rápidos antes de enviar PR.

Ten en cuenta:

- este comando es solo de revisión, no de cierre de tarea,
- no ejecutes `composer fix` ni `composer test` en esta fase,
- no ejecutes nunca tests de ningún tipo, aunque parezca que fallan,
- no intentes buscar, abrir ni analizar archivos de test,
- no intentes arreglar tests ni derivar trabajo adicional fuera del diff staged,
- no hagas commit automáticamente,
- no modifiques archivos en esta fase salvo que se indique explícitamente.

Limítate exclusivamente al diff staged y a `CHANGELOG.md` si está incluido en ese diff.

Prioriza:

1. claridad del scope del commit,
2. consistencia entre diff y `CHANGELOG.md`,
3. impacto SemVer,
4. riesgos rápidos antes del PR.

Salida final:

- alcance del commit
- estado de changelog
- impacto SemVer
- archivos staged
- riesgos antes del PR
