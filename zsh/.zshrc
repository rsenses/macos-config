# OPTIONS ========================================
HISTFILE=~/.zsh_history
HISTSIZE=1000000
SAVEHIST=1000000

setopt AUTOCD # EXTENDEDGLOB MENUCOMPLETE NOMATCH
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
setopt HIST_REDUCE_BLANKS   # Remove unnecessary blank lines.
setopt SHARE_HISTORY
# beeping is annoying
unsetopt BEEP

autoload -U compinit; compinit
zstyle ':completion:*' matcher-list 'm:{a-zA-Z}={A-Za-z}' 'r:|[._-]=* r:|=*' 'l:|=* r:|=*'

# set -o vi

# EVALS =========================================
if command -v zoxide >/dev/null 2>&1; then
  eval "$(zoxide init --cmd cd zsh)"
fi

# if command -v nodenv >/dev/null 2>&1; then
#   eval "$(nodenv init -)"
# fi

if command -v fzf >/dev/null 2>&1; then
  eval "$(fzf --zsh)"
fi

if command -v starship >/dev/null 2>&1; then
  eval "$(starship init zsh)"
fi

# ALIASES ========================================
if [ -f ~/.config/zsh/.zshaliases ]; then
source ~/.config/zsh/.zshaliases
fi

# FZF ========================================
if [ -f ~/.config/zsh/.zshfzf ]; then
source ~/.config/zsh/.zshfzf
fi

# Functions ========================================
if [ -f ~/.config/zsh/.zshfunctions ]; then
    source ~/.config/zsh/.zshfunctions
fi

# Cargar variables de entorno personalizadas (incluyendo API Keys)
if [ -f ~/.config/zsh/.zshvars ]; then
    source ~/.config/zsh/.zshvars
fi

# ZSH PLUGINS ========================================
[[ -r "$HOMEBREW_PREFIX/share/zsh-syntax-highlighting/zsh-syntax-highlighting.zsh" ]] && \
  source "$HOMEBREW_PREFIX/share/zsh-syntax-highlighting/zsh-syntax-highlighting.zsh"

# Colors
autoload -Uz colors && colors
export CLICOLOR=1  # macOS ls colors

# autoload -U up-line-or-beginning-search
# autoload -U down-line-or-beginning-search

# KEYBINDINGS ============================================
bindkey "^H" backward-delete-char
bindkey "^?" backward-delete-char
# bindkey "^[[A" up-line-or-beginning-search
# bindkey "^[[B" down-line-or-beginning-search
bindkey '^y' autosuggest-accept

if command -v wt >/dev/null 2>&1; then eval "$(command wt config shell init zsh)"; fi
