# VARS ========================================
export BAT_THEME=kanagawa
export ARTISAN_OPEN_ON_MAKE_EDITOR=vim
export LANG=es_ES.UTF-8
export EDITOR=/opt/homebrew/bin/nvim
export HOMEBREW_PREFIX=/opt/homebrew
export OLLAMA_API_BASE=http://127.0.0.1:11434
export SSH_AUTH_SOCK=/Users/rubensilvarodriguez/.bitwarden-ssh-agent.sock
export RIPGREP_CONFIG_PATH="$HOME/.ripgreprc"
export XDG_CONFIG_HOME="$HOME/.config"

typeset -gU path PATH

if [ -x /opt/homebrew/bin/brew ]; then
  eval "$(/opt/homebrew/bin/brew shellenv)"
fi

if command -v mise >/dev/null 2>&1; then
  eval "$(mise activate zsh)"
fi
