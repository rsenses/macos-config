# VARS ========================================
export BAT_THEME=kanagawa
export ARTISAN_OPEN_ON_MAKE_EDITOR=nvim
export LANG=es_ES.UTF-8
export EDITOR=/opt/homebrew/bin/nvim
export HOMEBREW_PREFIX=/opt/homebrew
export OLLAMA_API_BASE=http://127.0.0.1:11434
export RIPGREP_CONFIG_PATH="$HOME/.ripgreprc"
export XDG_CONFIG_HOME="$HOME/.config"
export LEAN_CTX_PI_MODE=replace
export PASSWORD_STORE_ENABLE_EXTENSIONS=true
export PASSWORD_STORE_EXTENSIONS_DIR="$HOME/.password-store/.extensions"
export ARGON_API_URL="https://argon.metech.es/api"
export ARGON_MARKDOWN_PATH="$HOME/Documents/Argon/tasks.md"

# Machine-local secrets live outside the tracked configuration.
[[ -r "$HOME/.zshenv.local" ]] && source "$HOME/.zshenv.local"

# Make configured mise tools win over later PATH additions.
export MISE_ACTIVATE_AGGRESSIVE=1
