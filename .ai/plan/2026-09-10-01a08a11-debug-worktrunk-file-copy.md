# Plan: debug-worktrunk-file-copy
- Status: in-progress
- Created: 2026-09-10
- Session ID: 01a08a11

## Goal
Diagnosticar y mejorar la configuración de Worktrunk en el repositorio de dotfiles, verificando por qué los ficheros ignorados de `~/dev/www/cobra.wyrko.es` no se copian o quedan desactualizados en los worktrees.

## Current Step
Corrección aplicada y verificada con `wt config show`, `wt hook post-switch --dry-run` y dos pruebas aisladas en repositorios temporales.

## Spec / Contract
- La configuración compartida vive en `worktrunk/.config/worktrunk/config.toml` y está enlazada a `~/.config/worktrunk`.
- Worktrunk v0.77.0 solo copia ficheros que Git considera ignorados; no copia ficheros trackeados y, sin `--force`, no reemplaza destinos existentes.
- El hook `pre-start` se ejecuta únicamente al crear un worktree; `post-start` se ejecuta en segundo plano también una sola vez al crear uno.
- No mostrar ni registrar el contenido de secretos (`.env`, `auth.json`, etc.).
- Preservar los cambios preexistentes del worktree.

## Tasks
- [x] Inspeccionar configuración efectiva y enlace de `~/.config/worktrunk`.
- [x] Inspeccionar `.gitignore`, `.config/wt.toml` y worktrees de Cobra sin exponer secretos.
- [x] Aplicar la mejora mínima acordada a la configuración.
- [x] Verificar configuración, selección de ficheros y estado final.

## Findings
- El hook global `pre-start copy = "wt step copy-ignored"` sí está cargado.
- En Cobra, `.env`, `.phpunit.result.cache`, `.php-cs-fixer.cache`, `auth.json`, `_ide_helper.php`, `vendor`, `node_modules`, `public/build`, etc. están ignorados y son elegibles.
- `wt step copy-ignored --from main --to develop --dry-run --force` muestra `.env` entre 2872 entradas copiables.
- Los worktrees existentes sí tienen `.env`, pero su SHA-256 difiere del `.env` del worktree principal: la copia inicial quedó obsoleta. Sin `--force`, los destinos existentes se omiten.
- `~/dev/www/cobra.wyrko.es/.worktreeinclude` no existe; por tanto la orden actual usa el modo por defecto de copiar todo lo ignorado, no una lista explícita.
- `.envrc` tampoco existe en ninguno de los worktrees; el hook `envrc` solo lo copia si existe en el principal.

## Verification
- `wt config show` acepta la configuración y muestra `post-switch user:copy_missing`.
- `wt hook post-switch --dry-run` muestra el nuevo comando para Cobra.
- En un repositorio temporal, el hook copió un `.env` ausente y conservó un `.env` ya existente distinto.
- Cobra no fue modificado y sus tres worktrees conservan su estado Git limpio.
- `git diff --check` pasa para el cambio de dotfiles.

## Stop Rules
- No copiar ni sobrescribir secretos durante el diagnóstico.
- No modificar `~/dev/www/cobra.wyrko.es` ni sus worktrees salvo petición explícita; la corrección debe quedar en dotfiles, y cualquier sincronización real se hará aparte.
- No añadir `--force`: la sincronización destructiva requiere una decisión explícita posterior.

## Validation Policy

## Validation

## Follow-up: Herdr / Pi
- [x] Confirmar contra la documentación oficial que Pi usa hooks de ciclo de vida cuando la integración está instalada y que `ui.toast.delivery = "herdr"` es la configuración correcta para toasts dentro de Herdr.
- [x] Actualizar la integración oficial de Pi de v3 a v8 con `herdr integration install pi`; el archivo está hardlinkado desde `pi/.pi/agent/extensions/herdr-agent-state.ts`, por lo que el cambio queda en los dotfiles sin exponer secretos.
- [x] Verificar `herdr integration status`, `herdr config check` y `herdr server reload-config`.
- [x] Probar una sesión Pi nueva: `herdr agent explain` muestra `screen_detection_skipped=true` y `full_lifecycle_hook_authority`; durante un prompt pasó por `working` y terminó en `done`/`idle`.
- [ ] Reiniciar las sesiones Pi ya abiertas para que carguen v8; la recarga de `config.toml` no recarga extensiones de Pi.

## Herdr Findings
- La causa del panel sin cambios de color/estado era la integración instalada obsoleta (v3), no una clave inválida de `config.toml`.
- Las sesiones existentes seguían mostrando `screen_detection_skip_reason` ausente y `default_known_agent_idle_fallback`; una sesión nueva con v8 usa la autoridad de hooks.
- `show_agent_labels_on_pane_borders = true` solo añade la etiqueta en los bordes de paneles divididos; no sustituye el reporte de estado.
- `ui.toast.delivery = "herdr"` muestra toasts dentro de la interfaz y Herdr no muestra toasts para la pestaña activa; usar `system` o `terminal` si se necesitan notificaciones externas.
