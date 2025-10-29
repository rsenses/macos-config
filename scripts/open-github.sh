#!/usr/bin/env bash

set -euo pipefail

# Determine the working directory of the current tmux pane (fallback to CWD).
if [[ -n "${TMUX_PANE:-}" ]]; then
  pane_dir=$(tmux display-message -p -t "$TMUX_PANE" '#{pane_current_path}')
else
  pane_dir=$PWD
fi

cd "$pane_dir"

remote=$(git remote get-url origin 2>/dev/null || true)
if [[ -z "${remote:-}" ]]; then
  echo "No remote found" >&2
  exit 1
fi

case "$remote" in
  git@github.com:*)
    repo=${remote#git@github.com:}
    ;;
  https://github.com/*)
    repo=${remote#https://github.com/}
    ;;
  git://github.com/*)
    repo=${remote#git://github.com/}
    ;;
  *)
    echo "Remote is not a GitHub URL: $remote" >&2
    exit 1
    ;;
esac

repo=${repo%.git}
url="https://github.com/$repo"

open "$url"
