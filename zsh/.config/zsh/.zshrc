[ -r "$ZDOTDIR/.secrets" ] && . "$ZDOTDIR/.secrets"

# OPTIONS ========================================
setopt AUTOCD EXTENDEDGLOB MENUCOMPLETE NOMATCH
setopt BANG_HIST              # Treat the '!' character specially during expansion.
setopt EXTENDED_HISTORY       # Write the history file in the ':start:elapsed;command' format.
setopt INC_APPEND_HISTORY     # Write to the history file immediately, not when the shell exits.
setopt HIST_EXPIRE_DUPS_FIRST # Expire a duplicate event first when trimming history.
setopt HIST_IGNORE_DUPS       # Do not record an event that was just recorded again.
setopt HIST_IGNORE_ALL_DUPS   # Delete an old recorded event if a new event is a duplicate.
setopt HIST_FIND_NO_DUPS      # Do not display a previously found event.
setopt HIST_IGNORE_SPACE      # Do not record an event starting with a space.
setopt HIST_SAVE_NO_DUPS      # Do not write a duplicate event to the history file.
setopt HIST_VERIFY            # Do not execute immediately upon history expansion.
setopt SHARE_HISTORY
# beeping is annoying
unsetopt BEEP

HISTFILE=~/.zsh_history
HISTSIZE=1000000
SAVEHIST=1000000
stty stop undef # Disable ctrl-s to freeze terminal.
zle_highlight=('paste:none')
zle-line-init() {
  if [[ "$ZLE_LOCAL_HISTORY_SET" != "1" ]]; then
    ZLE_LOCAL_HISTORY_SET=1
    zle set-local-history 1
  fi
}
zle -N zle-line-init

# EVALS =========================================
# Inicialización de herramientas interactivas
if command -v zoxide >/dev/null 2>&1; then
  eval "$(zoxide init --cmd cd zsh)"
fi

if command -v nodenv >/dev/null 2>&1; then
  eval "$(nodenv init -)"
fi

if command -v fzf >/dev/null 2>&1; then
  eval "$(fzf --zsh)"
fi

if command -v starship >/dev/null 2>&1; then
  eval "$(starship init zsh)"
fi

# ALIASES ========================================
source $ZDOTDIR/zsh-aliases

# FZF ========================================
source $ZDOTDIR/zsh-fzf

# Functions ========================================
source $ZDOTDIR/zsh-functions

# ZSH PLUGINS ========================================
[[ -r "$HOMEBREW_PREFIX/share/zsh-autosuggestions/zsh-autosuggestions.zsh" ]] && \
  source "$HOMEBREW_PREFIX/share/zsh-autosuggestions/zsh-autosuggestions.zsh"
[[ -r "$HOMEBREW_PREFIX/share/zsh-syntax-highlighting/zsh-syntax-highlighting.zsh" ]] && \
  source "$HOMEBREW_PREFIX/share/zsh-syntax-highlighting/zsh-syntax-highlighting.zsh"

 # Cargar variables de entorno personalizadas (incluyendo API Keys)
if [ -f ~/.config/zsh/.zshvars ]; then
    source ~/.config/zsh/.zshvars
fi

autoload -U up-line-or-beginning-search
autoload -U down-line-or-beginning-search
zle -N up-line-or-beginning-search
zle -N down-line-or-beginning-search

# KEYBINDINGS ============================================
bindkey -v
bindkey "^H" backward-delete-char
bindkey "^?" backward-delete-char
bindkey "^[[A" up-line-or-beginning-search
bindkey "^[[B" down-line-or-beginning-search
bindkey '^y' autosuggest-accept
