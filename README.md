# Dotfiles

Configuración personal para macOS centrada en Neovim, zsh, Git, Herdr,
Worktrunk y Pi.

## Instalación

Desde una copia local del repositorio:

```sh
./install
```

El instalador comprueba las Command Line Tools de Xcode, prepara Homebrew,
ejecuta `brew bundle` con `Brewfile`, instala Pi y el servidor LSP de Stylelint
mediante npm, y enlaza los paquetes de dotfiles existentes con GNU Stow.

Revisa `Brewfile` antes de ejecutarlo: la instalación puede añadir fórmulas,
casks y paquetes npm al sistema. No se ejecuta automáticamente ninguna
importación SQL ni servidor de proyecto.

## Desarrollo local

`bin/.local/bin/dev` documenta su ciclo de vida y sus pruebas aisladas en
[`docs/dev.md`](docs/dev.md). La política para separar configuración de Git y
estado privado está en [`docs/git-privacy.md`](docs/git-privacy.md).

Las pruebas se ejecutan sin tocar el estado personal:

```sh
PYTHONDONTWRITEBYTECODE=1 python3 -m unittest discover -s tests
```
