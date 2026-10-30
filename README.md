# Dotfiles

Configuración personal para macOS y Linux, gestionada con [GNU Stow](https://www.gnu.org/software/stow/). Incluye configuraciones para Neovim, zsh, Git, mise, Herdr, Worktrunk, tmux, Ghostty, Yazi, Salt, ripgrep, sesh, OpenCode, Pi y Plannotator.

## Instalación

El repositorio no incluye un instalador automático. Desde una copia local del repositorio, instala GNU Stow y ejecuta:

```sh
git clone <url-del-repositorio> ~/dev/contrib/dotfiles
cd ~/dev/contrib/dotfiles

stow --dir="$PWD" --target="$HOME" \
  bin ghostty git herdr mise nvim opencode php phpactor pi plannotator \
  ripgrep salt sesh tmux worktrunk yazi zsh
```

El `--dir="$PWD"` hace que la instalación funcione aunque el repositorio esté en una ruta distinta de la histórica. Stow creará los enlaces en `$HOME` y `$HOME/.config`; revisa primero los conflictos si ya existen archivos en esas rutas.

Los paquetes principales son:

| Paquete | Destino principal |
| --- | --- |
| `bin` | `~/.local/bin` |
| `git` | `~/.gitconfig`, `~/.gitignore`, `~/.githooks` |
| `zsh` | `~/.zshenv`, `~/.zprofile`, `~/.zshrc`, `~/.config/zsh` |
| `nvim` | `~/.config/nvim` |
| `salt` | `~/.config/salt/salt.toml` |
| `herdr`, `worktrunk` | `~/.config/herdr`, `~/.config/worktrunk` |
| `mise` | Fragmento `~/.config/mise/conf.d/php-ini.toml` (se integra con `config.toml`) |
| `opencode`, `pi`, `plannotator` | Sus respectivos directorios de configuración en `$HOME` |
| `php` | `~/.config/php/8.4`, `~/.config/php/8.5` |
| `ghostty`, `phpactor`, `ripgrep`, `sesh`, `tmux`, `yazi` | Sus respectivos directorios o archivos en `$HOME` |

`Brewfile` es un inventario del entorno Homebrew personal, con fórmulas y casks principalmente orientados a macOS. No es necesario para usar Stow ni debe ejecutarse sin revisarlo en Ubuntu Server: los casks y algunas fórmulas pueden no estar disponibles allí.

El fragmento de mise selecciona `~/.config/php/<versión-major.minor>/php.ini` según la versión de PHP activa y configura PCOV: usa la ruta de Homebrew en macOS y `pcov.so` en el directorio de extensiones de PHP en Linux. En Linux, instala PCOV para cada versión de PHP de mise (`mise exec php@<versión> -- pecl install pcov`). El paquete `php` se instala en ambas plataformas para proporcionar los INI versionados. Los temporales de PHP/Composer usan el directorio temporal predeterminado del sistema; los dotfiles no lo redirigen a una carpeta dentro de `$HOME`.

### Paquetes globales de Composer

El fragmento de mise fija `COMPOSER_HOME` en `~/.config/composer`, compartido entre las versiones de PHP. Zsh añade `~/.config/composer/vendor/bin` al `PATH`. Los paquetes deben ser compatibles con la versión de PHP activa.

Los paquetes, `composer.json`, `composer.lock` y las credenciales de Composer son datos locales: no se guardan ni se enlazan desde este repositorio. Si ya tienes paquetes en una carpeta `.composer` dentro de una instalación de PHP de mise, migra su contenido a `~/.config/composer` antes de ejecutar `composer global update`; no sobrescribas una instalación de destino existente.

## Archivos locales

Estos archivos se excluyen deliberadamente del repositorio. Contienen secretos, identidad, rutas o ajustes específicos de cada máquina. Créelos directamente en las rutas indicadas; no los añadas al repositorio.

### `~/.zshenv.local`

`~/.zshenv` lo carga en todas las sesiones de zsh. Úsalo para secretos y variables que deban estar disponibles también en sesiones no interactivas:

```sh
# ~/.zshenv.local
export PRIVATE_API_KEY='reemplazar-por-el-valor-real'
export MACHINE_SPECIFIC_SETTING='valor-local'
```

No pongas aquí comandos que necesiten una terminal interactiva. El archivo puede protegerse con:

```sh
chmod 600 ~/.zshenv.local
```

### `~/.config/zsh/.zshvars`

`~/.zshrc` lo carga solo para sesiones interactivas. Úsalo para variables de APIs o ajustes personales que no necesiten estar presentes en todos los procesos:

```sh
# ~/.config/zsh/.zshvars
export OPENAI_API_KEY='reemplazar-por-el-valor-real'
export GITHUB_TOKEN='reemplazar-por-el-valor-real'
```

También debe mantenerse fuera del control de versiones y protegerse con `chmod 600`.

### `~/.gitconfig.local`

`git/.gitconfig` incluye este archivo al final. La configuración versionada activa la firma SSH de commits; el archivo local debe indicar la clave pública correspondiente:

```ini
# ~/.gitconfig.local
[user]
    signingkey = ~/.ssh/id_ed25519.pub

# Opcional: permite verificar firmas SSH localmente.
# [gpg "ssh"]
#     allowedSignersFile = ~/.config/git/allowed_signers
```

La clave privada nunca debe copiarse al repositorio. Para la firma SSH debe estar disponible mediante `ssh-agent`. El archivo `allowed_signers` es opcional y solo hace falta si se quiere verificar localmente la identidad de los firmantes.

## Dependencias y archivos externos

Stow solo enlaza configuraciones; no instala programas ni datos privados. Según las funciones que se utilicen, también pueden hacer falta:

- `git`, `zsh`, `stow`, `nvim`, `delta`, `fzf`, `starship`, `zoxide`, `mise`, `wt`, `herdr` y `lazygit`.
- `~/.ssh/config` y las claves SSH para conexiones remotas, `herdr --remote` y firma de commits. Un ejemplo mínimo es:

  ```ssh
  Host servidor
      HostName example.com
      User usuario
      IdentityFile ~/.ssh/id_ed25519
  ```

- TPM para tmux, instalado en `~/.config/tmux/plugins/tpm`, si se utiliza la configuración de tmux y sus plugins.
- `~/.tmux-cht-languages` para `tmux-cht.sh`. El archivo fuente está en la raíz de este repositorio y no lo instala Stow automáticamente; puede enlazarse así desde la raíz:

  ```sh
  ln -sfn "$PWD/.tmux-cht-languages" "$HOME/.tmux-cht-languages"
  ```

Los estados generados por las herramientas —por ejemplo, historial de zsh, cachés, `.env`, plugins de tmux y estado de Herdr, Worktrunk, Pi o Plannotator— no forman parte de la configuración versionada.

## Notas de configuración

- zsh activa `compinit` en macOS y Linux antes de la integración de Worktrunk.
- Neovim usa el portapapeles nativo en macOS y OSC 52 en Linux/remoto.
- Git usa un hook global de mensajes Conventional Commits, rebase al hacer pull, limpieza de referencias remotas y firma SSH.
- Worktrunk prepara los worktrees con los archivos ignorados y, si está disponible, instala las herramientas declaradas por mise.

## Servidor local de proyectos (`dev`)

`~/.local/bin/dev` gestiona el servidor local de un proyecto con `up`, `down`, `reload`, `status` y `down-all`. La detección del servidor principal no cambia: Laravel con `artisan`, PHP con `public/` o `web/`, o `npm run dev` en un `package.json`.

El archivo `.config/caddy` del proyecto puede declarar comandos auxiliares que `dev` inicia como procesos supervisados en segundo plano. La sintaxis es una línea `EXTRAS=` repetida por cada comando:

```sh
# <proyecto>/.config/caddy
PORT=8021
EXTRAS=npm run api:dev
EXTRAS=npm run otro:dev
```

Cada valor es un comando completo que se ejecuta con `bash -c` desde la raíz del proyecto. El archivo de configuración se considera de confianza: los comandos solo se ejecutan al hacer `up` o `reload`, nunca al consultar `status` ni al hacer `down`. El comando no debe desprenderse ni daemonizarse: debe seguir ejecutándose para que `dev` supervise ese proceso y sus descendientes. La comprobación de arranque detecta procesos que terminan enseguida, pero no espera a que el servicio esté listo.

Cada extra tiene su propio log y estado dentro de `/tmp/dev-<hash>.extras/` (o bajo `DEV_STATE_PREFIX` si se define). `status` muestra el comando registrado, si sigue activo y la ruta de su log. `down`, `down-all` y la fase de parada de `reload` usan el estado registrado, no la configuración actual: cambiar o quitar una línea `EXTRAS=` no impide detener el comando que se inició antes. `reload` inicia después los comandos de la configuración actual. Si un extra falla al arrancar, `up` detiene también los extras ya iniciados y el servidor principal, y no publica la ruta de Caddy.

Los extras no reciben una ruta de Caddy propia; las rutas adicionales se siguen declarando con `PROXIES=...` como antes.

## Diagnóstico temporal de caché de Pi

`cache-diagnostics.ts` se carga como extensión local tras `/reload` o al reiniciar Pi. No cambia peticiones ni añade avisos o herramientas.
Guarda un archivo por ejecución, `~/.pi/agent/cache-diagnostics/requests.<run>.jsonl`, y su copia rotada `.1` (unos 2 MiB cada uno; respeta `PI_CODING_AGENT_DIR`). Son archivos privados e ignorados por Git.
Solo guarda huellas con una clave aleatoria no persistida, metadatos y uso de tokens; no guarda conversaciones ni credenciales.
Las huellas se comparan dentro del mismo `run`; `request` enlaza petición, respuesta y uso. Los bloques de entrada permiten localizar cambios de prefijo.
Observa el payload en su posición dentro de los hooks, no garantiza los bytes finales enviados ni identifica causas internas del proveedor. Las cabeceras de respuesta dependen del transporte.
Si falla el almacenamiento, deja de registrar sin interrumpir Pi. Para desactivarla, retirar la extensión y recargar; los logs se pueden borrar.

## Pruebas

Las pruebas se ejecutan sin tocar el estado personal:

```sh
PYTHONDONTWRITEBYTECODE=1 python3 -m unittest discover -s tests
```
