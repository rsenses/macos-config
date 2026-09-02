# Plan: dynamic-dev-ports
- Status: in-progress
- Created: 2026-09-02
- Session ID: 01a060bf

## Goal
Cambiar `bin/.local/bin/dev` para asignar puertos dinámicos y gestionar colisiones de dominio entre proyectos/worktrees, sin modificar la configuración persistente de aliases/dominios salvo dejar de usar `PORT`.

## Current Step
Configuración y pruebas completadas; queda aplicar el reinicio privilegiado de Caddy para reemplazar el certificado cacheado.

## Spec / Contract
- `dev up` elige el primer puerto libre desde 8000 hasta 8999 comprobándolo contra procesos reales (`lsof`); no mantiene un registro de reservas.
- Arranca `php artisan serve --host=127.0.0.1 --port=<puerto>` desde la raíz absoluta del proyecto/worktree.
- La metadata efímera vive en `/tmp/dev-<hash>.state`, con hash estable de la ruta absoluta para distinguir worktrees; incluye proyecto, dominio/hosts, puerto y PID.
- La metadata de puerto se conserva para `status` y Caddy, no para decidir disponibilidad.
- `dev up` detecta otras instancias activas con el mismo dominio o alias. Para una instancia de otro proyecto/worktree, informa y pregunta si debe detenerla; respuesta negativa cancela.
- `dev down`, `status`, `reload` y `down-all` usan el estado efímero; `down` elimina el estado de la instancia.
- Caddy continúa usando el dominio base y aliases de `.config/caddy`; su snippet apunta al puerto dinámico.
- No existe `CHANGELOG.md` en la raíz ni infraestructura de tests para este script.

## Findings
- Antes, `load_project_config()` leía `PORT` y `ALIASES` desde `$PROJECT_DIR/.config/caddy`; `pick_port()` exigía el puerto fijo.
- Antes, `start_php_server()` ejecutaba `php -S`, no Artisan, y guardaba PID/log por `REPO_NAME`.
- Antes, `down` mataba el PID por nombre de repositorio; `status` mostraba el puerto configurado; `down-all` recorría `/tmp/dev-*.pid`.
- Para worktrees, `REPO_NAME` se deriva del git common dir y se comparte; los PID/log/snippets actuales pueden colisionar.
- El Caddyfile global importa `/Users/rubensilvarodriguez/dev/caddy-sites/*.caddy`; cada snippet contiene `DOMAIN`, aliases y `reverse_proxy 127.0.0.1:$PORT`.
- El worktree ya tenía cambios no relacionados en `dev` (soporte `web/`, router `.ht.router.php`, regeneración de snippet); se conservaron.
- El dominio sigue siendo el actual (`<repo>.test`); si otra instancia usa ese host o un alias coincidente, se pide confirmación antes de reemplazarla.

## Tasks
- [x] Task 1: Implementar metadata temporal y hash por ruta.
- [x] Task 2: Implementar selección dinámica y arranque con Artisan.
- [x] Task 3: Implementar detección/prompt de dominio duplicado y adaptar Caddy.
- [x] Task 4: Adaptar `down`, `status`, `reload` y `down-all`.
- [x] Task 5: Ejecutar validaciones y pruebas manuales aisladas.
- [x] Task 6: Revisar diff y cerrar plan.

## Stop Rules
- No tocar cambios preexistentes ajenos en el worktree ni modificar configuraciones de proyectos bajo `~/dev/www`.
- No persistir puertos/estado dentro del proyecto.
- No borrar ni detener una instancia de otro dominio/proyecto sin confirmación explícita.

## Validation Policy
Usar `bash -n`, `git diff --check` sobre el archivo objetivo y pruebas aisladas con proyectos temporales/stubs o procesos reales; no iniciar Caddy ni servidores de proyectos del usuario salvo necesidad explícita.

## Validation
- `bash -n bin/.local/bin/dev`: OK.
- `git diff --check -- bin/.local/bin/dev`: OK.
- Proyecto temporal con `PORT` inválido/persistente: se ignoró, se eligió 8000, se generó Caddy y se arrancó `artisan serve`.
- Puerto 8000 ocupado por otro proceso: se eligió 8001 y Caddy recibió el puerto correcto.
- Dos proyectos/worktrees con el mismo dominio: `n` conservó el anterior; `s` lo detuvo y lanzó el nuevo; los estados usaron hashes distintos.
- `down` eliminó el estado y detuvo el servidor; `down-all` detuvo varias instancias.
- Prueba con Laravel real (`app.datarena.com`): `up` y `down` funcionaron; el PID de Artisan y el servidor hijo terminaron correctamente.
- No se añadieron tests persistentes porque el repositorio no tiene runner o suite para este script.
- `dev reload` desde el worktree de Cobra con `APP_URL='https://${APP_DOMAIN}'` heredado: OK; arrancó en 8000 y el log confirmó Artisan.
- `dev reload` de `/Users/rubensilvarodriguez/dev/www/keytools.es`, incluso con el mismo `APP_URL` heredado, devuelve `302 /login` directamente y a través de Caddy; el 502 reproducible corresponde al alias antiguo `svelte.keytools.es.test`, cuyo upstream `127.0.0.1:8025` no tiene ningún listener.
- `caddy adapt --config /opt/homebrew/etc/Caddyfile --adapter caddyfile`: OK; el endpoint activo refleja `lifetime=7d` e `intermediate_lifetime=30d`.

## Follow-up: caddy-local-cert-expiry
- [x] Confirmar la causa: Caddy mantenía en memoria un leaf de 12 h y un intermedio local de 7 días; un `reload` no recarga el certificado cacheado.
- [x] Configurar leafs internos de 7 días, intermedios de 30 días y `reload --force`; actualizar los snippets existentes.
- [ ] Reiniciar Caddy una vez y eliminar solo leafs/intermedio antiguos para aplicar la rotación inmediata (requiere privilegios de root; conservar el root CA).
- [x] Diagnosticar `dev reload`: un `APP_URL=https://${APP_DOMAIN}` heredado (por ejemplo desde direnv) impedía que Symfony construyera la request de consola; `dev` lo descarta y publica el upstream después de arrancar PHP.
