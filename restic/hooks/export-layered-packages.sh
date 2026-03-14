#!/usr/bin/env bash
set -euo pipefail

mkdir -p "$HOME/.local/state/backup"

rpm-ostree status --json \
  | jq -r '.deployments[0]."requested-packages"[]?' \
  > "$HOME/.local/state/backup/layered-packages.txt"
