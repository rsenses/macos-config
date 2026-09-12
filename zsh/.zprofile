# ~/.config/zsh/.zprofile
# Login-shell setup runs after the system profile has finished changing PATH.

if [[ -r "$HOME/.config/zsh/.zshpaths" ]]; then
  source "$HOME/.config/zsh/.zshpaths"
fi

# Make mise-managed tools available to applications launched from a login shell.
if command -v mise >/dev/null 2>&1; then
  eval "$(mise activate zsh --shims)"
fi
