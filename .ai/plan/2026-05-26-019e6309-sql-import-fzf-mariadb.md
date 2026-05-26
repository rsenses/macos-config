# Plan: sql-import-fzf-mariadb
- Status: done
- Created: 2026-05-26
- Session ID: 019e6309

## Goal
Crear un script en `bin/.local/bin/` para importar `.sql` y `.sql.gz` desde `~/data/work/docs/topics/general/sql` usando `fzf`, y elegir la base de datos local de MariaDB con `fzf`.

## Current Step
Validar el script creado y dejarlo listo para uso.

## Spec / Contract
- Script en `bin/.local/bin/`.
- Selección de archivo con `fzf`.
- Acepta `.sql` y `.sql.gz`.
- Selección de base de datos local con `fzf`.
- Usa `mariadb` contra `localhost`.

## Tasks
- [x] Crear script de importación.
- [x] Hacerlo ejecutable.
- [x] Validar sintaxis con `bash -n`.

## Stop Rules
- No añadir más abstracción.
- Mantener el script simple y directo.

## Validation Policy
- `bash -n` del script.

## Validation
- `bash -n bin/.local/bin/mariadb-import`
