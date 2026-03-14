#!/usr/bin/env bash
set -euo pipefail

mkdir -p "$HOME/.local/state/backup"

flatpak list --app --columns=application \
  > "$HOME/.local/state/backup/flatpaks.txt"
