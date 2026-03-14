#!/usr/bin/env bash
set -euo pipefail

mkdir -p "$HOME/.local/state/backup"

if command -v code >/dev/null 2>&1; then
  code --list-extensions \
    > "$HOME/.local/state/backup/vscode-extensions.txt"
else
  : > "$HOME/.local/state/backup/vscode-extensions.txt"
fi
