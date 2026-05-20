# ~/.config/zsh/.zprofile
# typeset -gU path PATH

# PATHS ========================================
# (opcional) Depurar: ver rápidamente qué php ve un login shell
# print -rl -- "PATH=$PATH"
# command -v -a php

if [[ $(uname) == "Darwin" ]]; then
    path=(
        "/opt/homebrew/bin"
        "/Applications/Visual Studio Code - Insiders.app/Contents/Resources/app/bin"
        "$HOME/go/bin"
        $path
    )
fi

path=(
    "$HOME/.cargo/bin"
    "$HOME/.local/bin"
    "$HOME/.composer/vendor/bin"
    $path
)
