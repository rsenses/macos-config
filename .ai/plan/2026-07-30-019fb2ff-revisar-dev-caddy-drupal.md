# Plan: revisar-dev-caddy-drupal
- Status: completado
- Created: 2026-07-30
- Session ID: 019fb2ff

## Goal
Comprobar compatibilidad de `bin/.local/bin/dev` y `/opt/homebrew/etc/Caddyfile` con Drupal.

## Findings
- El script `bin/.local/bin/dev` solo detecta `public/` como document root; el proyecto Drupal usa `web/`.
- Arranca `php -S` sin router (`php -S localhost:8080 -t web/` no usa un router script, lo que impide el bootstrap de Drupal).
- El snippet Caddy (`import snippets/drupal`) solo hace `reverse_profit` sin `rewrite` ni `try_files`, por lo que no maneja las rutas limpias de Drupal.
- `.config/caddy` no existe en el proyecto (no hay snippets propios).
- El Caddyfile global sí hace redirect HTTP -> HTTPS e importa snippets.

## Changes
- `bin/.local/bin/dev` modificado para detectar `web/` como document root además de `public/`. Cuando existe `web/.ht.router.php` se usa como router de `php -S`.
- Creado `/Users/rubensilvarodriguez/dev/www/escuelaunidadeditorial.es/.config/caddy` con contenido `PORT=8016`.
- `bin/.local/bin/dev` ahora regenera siempre el snippet Caddy en cada `dev up`, evitando desincronización cuando cambia PORT o ALIASES.

## Validation
- `bash -n bin/.local/bin/dev` OK (sintaxis válida).
- `dev up escuelaunidadeditorial.es` OK (servicio arranca sin errores).
- Raíz HTTPS responde HTTP 200.
- `/user/login` responde HTTP 200.
- `/node/1` responde HTTP 404 (página de contenido inexistente, no es fallo de routing — Drupal maneja la ruta correctamente y devuelve 404 porque el nodo no existe).
- Con PORT=8023: `bash -n bin/.local/bin/dev` OK, `dev up escuelaunidadeditorial.es` OK, raíz HTTPS responde HTTP 200.

## Status
completado
