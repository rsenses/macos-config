# VARS ========================================
export BAT_THEME=kanagawa
export ARTISAN_OPEN_ON_MAKE_EDITOR=vim
export LANG=es_ES.UTF-8
export EDITOR=/opt/homebrew/bin/nvim
export HOMEBREW_PREFIX=/opt/homebrew
export OLLAMA_API_BASE=http://127.0.0.1:11434
export SSH_AUTH_SOCK=/Users/rubensilvarodriguez/.bitwarden-ssh-agent.sock
export RIPGREP_CONFIG_PATH="$HOME/.ripgreprc"

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

# Preferir binarios GNU instalados con Homebrew (color y flags largos)
for gnubin in \
  /opt/homebrew/opt/coreutils/libexec/gnubin \
  /opt/homebrew/opt/grep/libexec/gnubin \
  /opt/homebrew/opt/diffutils/libexec/gnubin
do
  [[ -d $gnubin ]] && path=($gnubin $path)
done

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
