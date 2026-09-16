# Dotfiles

Configuración personal para macOS y Linux, gestionada con [GNU Stow](https://www.gnu.org/software/stow/). Incluye configuraciones para Neovim, zsh, Git, Herdr, Worktrunk, tmux, Ghostty, Yazi, ripgrep, sesh, OpenCode, Pi y Plannotator.

## Instalación

El repositorio no incluye un instalador automático. Desde una copia local del repositorio, instala GNU Stow y ejecuta:

```sh
git clone <url-del-repositorio> ~/dev/contrib/dotfiles
cd ~/dev/contrib/dotfiles

stow --dir="$PWD" --target="$HOME" \
  bin ghostty git herdr nvim opencode phpactor pi plannotator \
  ripgrep sesh tmux worktrunk yazi zsh
```

El `--dir="$PWD"` hace que la instalación funcione aunque el repositorio esté en una ruta distinta de la histórica. Stow creará los enlaces en `$HOME` y `$HOME/.config`; revisa primero los conflictos si ya existen archivos en esas rutas.

Los paquetes principales son:

| Paquete | Destino principal |
| --- | --- |
| `bin` | `~/.local/bin` |
| `git` | `~/.gitconfig`, `~/.gitignore`, `~/.githooks` |
| `zsh` | `~/.zshenv`, `~/.zprofile`, `~/.zshrc`, `~/.config/zsh` |
| `nvim` | `~/.config/nvim` |
| `herdr`, `worktrunk` | `~/.config/herdr`, `~/.config/worktrunk` |
| `opencode`, `pi`, `plannotator` | Sus respectivos directorios de configuración en `$HOME` |
| `ghostty`, `phpactor`, `ripgrep`, `sesh`, `tmux`, `yazi` | Sus respectivos directorios o archivos en `$HOME` |

`Brewfile` es un inventario del entorno Homebrew personal, con fórmulas y casks principalmente orientados a macOS. No es necesario para usar Stow ni debe ejecutarse sin revisarlo en Ubuntu Server: los casks y algunas fórmulas pueden no estar disponibles allí.

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

## Pruebas

Las pruebas se ejecutan sin tocar el estado personal:

```sh
PYTHONDONTWRITEBYTECODE=1 python3 -m unittest discover -s tests
```
