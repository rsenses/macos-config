# ~/.config/zsh/.zprofile
typeset -gU path PATH

# PATHS ========================================
# Asegurar entorno de Homebrew (por si /etc/zprofile tocó PATH)
if [ -x /opt/homebrew/bin/brew ]; then
  eval "$(/opt/homebrew/bin/brew shellenv)"
fi

# Priorizar explícitamente PHP 8.4 **después** de /etc/zprofile
path=(
  /opt/homebrew/opt/php@8.4/bin
  /opt/homebrew/opt/php@8.4/sbin
  $path
)

if [[ $(uname) == "Darwin" ]]; then
    path=(
        "/Applications/Visual Studio Code - Insiders.app/Contents/Resources/app/bin"
        "$HOME/go/bin"
        $path
    )
fi

path=(
    "$HOME/.local/bin"
    "$HOME/.composer/vendor/bin"
    $path
)
# (opcional) Depurar: ver rápidamente qué php ve un login shell
# print -rl -- "PATH=$PATH"
# command -v -a php
