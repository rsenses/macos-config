# ~/.zshenv (HOME)
export ZDOTDIR="$HOME/.config/zsh"

# Asegurar entorno de Homebrew (por si /etc/zprofile tocó PATH)
if [ -x /opt/homebrew/bin/brew ]; then
  eval "$(/opt/homebrew/bin/brew shellenv)"
fi
