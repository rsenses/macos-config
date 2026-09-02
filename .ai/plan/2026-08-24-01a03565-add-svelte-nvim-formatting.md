# Plan: add-svelte-nvim-formatting
- Status: completed
- Created: 2026-08-24
- Session ID: 01a03565

## Goal
Agregar soporte de Svelte en Neovim: LSP, Treesitter y formato con Conform/prettierd.

## Current Step
Implementación y validación completadas.

## Spec / Contract
- Los archivos `.svelte` deben usar el filetype y parser Svelte.
- El LSP `svelte` debe quedar habilitado mediante nvim-lspconfig.
- Conform debe usar `prettierd` al formatear Svelte.

## Tasks
- [x] Añadir `svelte` al LSP habilitado.
- [x] Añadir `svelte` a los parsers de Treesitter.
- [x] Añadir `svelte` a los formatters de Conform.

## Stop Rules
No modificar configuraciones ajenas a Neovim ni instalar dependencias globales sin petición explícita.

## Validation Policy
Usar comprobaciones headless y revisar solo el diff de los archivos tocados; preservar cambios preexistentes del worktree.

## Validation
- Neovim headless cargó la configuración sin errores.
- El filetype de `Component.svelte` es `svelte`.
- El parser Treesitter Svelte se creó correctamente tras instalarlo localmente.
- `vim.lsp.is_enabled('svelte')` devolvió `true`.
- Conform reportó `prettierd` disponible para Svelte.
- `git diff --check` de los archivos tocados pasó; el check global solo reporta whitespace preexistente en `ghostty/.config/ghostty/config`.

## Remaining
El LSP requiere `svelte-language-server` y el formatter requiere `prettier-plugin-svelte` en cada proyecto Svelte.
