# Plan: debug-drupal-escuelaunidadeditorial
- Status: complete
- Created: 2026-09-03
- Session ID: 01a060bf

## Goal
Diagnosticar por qué el proyecto Drupal en `/Users/rubensilvarodriguez/dev/www/escuelaunidadeditorial.es` dejó de funcionar con el flujo local `dev`/Caddy y corregir solo lo necesario.

## Current Step
Diagnóstico y corrección validados; el proyecto Drupal queda levantado por `dev`.

## Spec / Contract
- No modificar cambios preexistentes ni archivos fuera del proyecto salvo el snippet Caddy generado o `bin/.local/bin/dev` si la causa es del flujo común.
- Mantener dominios y aliases definidos en `.config/caddy`.
- No persistir puertos ni estado dentro del proyecto.
- Validar con el comando `dev` y una petición HTTP(S) local antes de finalizar.

## Tasks
- [x] Task 1: Inspeccionar configuración Drupal, `.config/caddy`, estado efímero y procesos.
- [x] Task 2: Reproducir el fallo directo contra PHP y a través de Caddy.
- [x] Task 3: Aplicar la corrección mínima y validar.
- [x] Task 4: Documentar diagnóstico y resultado.

## Findings
- El proyecto es Drupal 10.6.15 con docroot `web/`, router `web/.ht.router.php` y no tiene `artisan` ni `.config/caddy`.
- `dev` intentaba ejecutar `php artisan serve`; el proceso terminaba con `Could not open input file: artisan`, dejaba el snippet antiguo en `8023` y Caddy devolvía 502.
- Drupal necesita arrancar el servidor integrado desde `web/`; desde la raíz resolvía `core/core.services.yml` contra una ruta inexistente.
- Con `php -S ... -t web web/.ht.router.php` desde `web/`, la aplicación responde correctamente.

## Validation
- `dev up /Users/rubensilvarodriguez/dev/www/escuelaunidadeditorial.es`: OK, puerto dinámico `8001` y snippet actualizado.
- `/` y `/user/login` devuelven `200` directamente y a través de Caddy; `/` entrega la página Drupal.
- Persisten avisos deprecados de módulos contribuidos al usar PHP 8.4, pero no provocan 502.

## Stop Rules
- No ejecutar migraciones, borrar cachés/base de datos ni reinstalar dependencias sin evidencia y confirmación.
- No revertir cambios no relacionados del worktree.

## Validation Policy

## Validation
