# VARS ========================================
export BAT_THEME=kanagawa
export ARTISAN_OPEN_ON_MAKE_EDITOR=vim
export LANG=es_ES.UTF-8
export EDITOR=/opt/homebrew/bin/nvim
export HOMEBREW_PREFIX=/opt/homebrew
export OLLAMA_API_BASE=http://127.0.0.1:11434
export SSH_AUTH_SOCK=/Users/rubensilvarodriguez/.bitwarden-ssh-agent.sock

# Homebrew
if [ -x /opt/homebrew/bin/brew ]; then
  eval "$(/opt/homebrew/bin/brew shellenv)"
fi

# PATHS ========================================
if [[ $(uname) == "Darwin" ]]; then
    export PATH="/opt/homebrew/opt/php@8.4/bin:/opt/homebrew/opt/php@8.4/sbin:$PATH"
    export PATH="/opt/homebrew/bin:$PATH"
    export PATH="/opt/homebrew/sbin:$PATH"
    export PATH="/Applications/Visual Studio Code - Insiders.app/Contents/Resources/app/bin:$PATH"
    export PATH="/opt/homebrew/opt/mariadb/bin:$PATH"
    export PATH="$HOME/go/bin:$PATH"
fi

export PATH="$HOME/.local/bin:$PATH"
export PATH="$HOME/.composer/vendor/bin:$PATH"
