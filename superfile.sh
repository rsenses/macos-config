#!/bin/bash

# Required parameters:
# @raycast.schemaVersion 1
# @raycast.title Superfile Downloads
# @raycast.mode silent

# Optional parameters:
# @raycast.icon 📁

osascript <<'EOF'
tell application "Ghostty"
    activate

    set cfg to new surface configuration
    set initial working directory of cfg to POSIX path of (path to downloads folder)
    set command of cfg to "spf"

    set win to front window
    set newTab to new tab in win with configuration cfg

    focus focused terminal of newTab
end tell
EOF
