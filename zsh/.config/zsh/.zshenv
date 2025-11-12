# VARS ========================================
export BAT_THEME=kanagawa
export ARTISAN_OPEN_ON_MAKE_EDITOR=vim
export LANG=es_ES.UTF-8
export EDITOR=/opt/homebrew/bin/nvim
export HOMEBREW_PREFIX=/opt/homebrew
export OLLAMA_API_BASE=http://127.0.0.1:11434
export SSH_AUTH_SOCK=/Users/rubensilvarodriguez/.bitwarden-ssh-agent.sock

typeset -gU path PATH

# PATHS ========================================
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
