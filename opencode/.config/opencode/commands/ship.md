---
description: Revisión final antes de commit
agent: plan
model: opencode/mimo-v2-flash-free
---

Estoy a punto de commitear estos cambios.

Rama actual:
!`git branch --show-current`

Estado:
!`git status --short`

Diff staged:
!`git diff --cached --stat`

Archivos en changelogs:
!`bash -lc 'ls -1 changelogs 2>/dev/null | tail -20 || true'`

Revisa esto y responde:

1. si el commit está bien acotado,
2. si falta changelog o está incompleto,
3. qué tipo y scope Conventional Commit encajan mejor,
4. un mensaje final recomendado en formato `type(scope): summary`,
5. riesgos rápidos antes de enviar PR---
   name: task-finalizer
   description: Use when closing a task to run project fix/test flows, verify changelog, and prepare a safe Conventional Commit.

---

When finishing work:

- then run the project's standard test command,
- verify there is an appropriate changelog entry in `changelogs/`,
- do not auto-commit,
- propose a Conventional Commit message in the format `type(scope): summary`.

Prioritize:

1. formatting and autofixable issues
2. quality and test failures
3. changelog completeness
4. commit scope clarity

Final output:

- checks run
- failures remaining
- changelog status
- files touched
- Conventional Commit suggestion.
