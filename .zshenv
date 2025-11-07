# ~/.zshenv (HOME)
export ZDOTDIR="$HOME/.config/zsh"
# Si hay un .zshenv “real” en ZDOTDIR, cárgalo
[ -r "$ZDOTDIR/.zshenv" ] && . "$ZDOTDIR/.zshenv"
