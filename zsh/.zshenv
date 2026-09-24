# VARS ========================================
export BAT_THEME=kanagawa
export ARTISAN_OPEN_ON_MAKE_EDITOR=nvim
export LANG=es_ES.UTF-8
export EDITOR=nvim

# Ubuntu/Debian may run compinit from /etc/zsh/zshrc.
# The user configuration enables it explicitly only on macOS.
if [[ "$OSTYPE" != darwin* ]]; then
    skip_global_compinit=1
fi

export OLLAMA_API_BASE=http://127.0.0.1:11434
export RIPGREP_CONFIG_PATH="$HOME/.ripgreprc"
export XDG_CONFIG_HOME="$HOME/.config"

# Keep PHP CLI and Composer temporary files on persistent home storage on Linux.
if [[ "$OSTYPE" == linux* ]]; then
    php_ini_scan_dir="$HOME/.config/php/conf.d"
    if [[ -n "${PHP_INI_SCAN_DIR:-}" ]]; then
        case ":$PHP_INI_SCAN_DIR:" in
            *":$php_ini_scan_dir:"*) ;;
            *) PHP_INI_SCAN_DIR="$php_ini_scan_dir:$PHP_INI_SCAN_DIR" ;;
        esac
    else
        PHP_INI_SCAN_DIR="$php_ini_scan_dir:"
    fi
    export PHP_INI_SCAN_DIR
    unset php_ini_scan_dir
fi

export LEAN_CTX_PI_MODE=replace
export PASSWORD_STORE_ENABLE_EXTENSIONS=true
export PASSWORD_STORE_EXTENSIONS_DIR="$HOME/.password-store/.extensions"
export ARGON_API_URL="https://argon.metech.es/api"
export ARGON_MARKDOWN_PATH="$HOME/Documents/Argon/tasks.md"

# Machine-local secrets live outside the tracked configuration.
[[ -r "$HOME/.zshenv.local" ]] && source "$HOME/.zshenv.local"

# Make configured mise tools win over later PATH additions.
export MISE_ACTIVATE_AGGRESSIVE=1

# Expose mise and its shims to non-login shells (e.g. Pi Web subprocesses).
for mise_path in "$HOME/.local/bin" "$HOME/.local/share/mise/shims"; do
    if [[ -d "$mise_path" && ":$PATH:" != *":$mise_path:"* ]]; then
        PATH="$mise_path:$PATH"
    fi
done
export PATH
unset mise_path
