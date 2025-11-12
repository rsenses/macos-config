# ~/.config/zsh/.zprofile

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

# (opcional) Depurar: ver rápidamente qué php ve un login shell
# print -rl -- "PATH=$PATH"
# command -v -a php
