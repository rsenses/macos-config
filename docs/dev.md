# `dev`

`bin/.local/bin/dev` sirve proyectos PHP locales detrás de Caddy:

```text
dev up [nombre]
dev down [nombre]
dev reload [nombre]
dev status [nombre]
dev down-all
```

El comportamiento normal conserva los directorios y valores existentes: busca
proyectos en `~/dev/www`, usa dominios `<repositorio>.test`, asigna puertos
`8000–8999` y guarda el estado bajo `/tmp/dev-*`.

Al detener un proyecto se retira su snippet `.caddy` y se recarga Caddy cuando
está disponible. Antes de señalar un PID se comprueba el comando PHP, el puerto
y la hora de inicio registrada; los procesos hijos de `artisan serve` se
comprueban como descendientes. Si no se puede verificar la identidad, se deja
el proceso intacto y el comando devuelve error.

Las operaciones mutantes (`up`, `down` y `down-all`) usan un bloqueo de
filesystem bajo `/tmp/dev.lock` para no pisarse entre sí. Se puede cambiar la
ubicación del estado, snippets, Caddyfile, endpoint administrativo y bloqueo
para pruebas aisladas:

```sh
DEV_SITES_DIR=/tmp/dev-test/sites \
DEV_STATE_PREFIX=/tmp/dev-test/state/dev \
DEV_CADDYFILE=/tmp/dev-test/Caddyfile \
DEV_CADDY_ADMIN=http://127.0.0.1:2019 \
DEV_LOCK_DIR=/tmp/dev-test/dev.lock \
dev status
```

Las pruebas no arrancan PHP, Caddy ni `sudo`; usan dobles de comandos en
`tests/test_dev.py`.
