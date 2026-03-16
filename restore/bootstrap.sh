#!/usr/bin/env bash
set -euo pipefail

STATE_DIR="$HOME/.local/state/backup"

count_entries() {
  local file="$1"
  awk 'NF { count++ } END { print count + 0 }' "$file"
}

print_missing() {
  local label="$1"
  local file="$2"
  echo "${label}: skipped (${file} not found or empty)"
}

run_step() {
  local key="$1"
  local label="$2"
  local file="$3"
  shift 3

  if [[ ! -s "$file" ]]; then
    STEP_STATUS["$key"]="skipped"
    print_missing "$label" "$file"
    return 0
  fi

  local count
  count="$(count_entries "$file")"
  echo "${label}: found ${count} entr$( [[ "$count" -eq 1 ]] && echo "y" || echo "ies" ) in $file"

  if "$@"; then
    STEP_STATUS["$key"]="done (${count})"
    echo "${label}: completed"
  else
    STEP_STATUS["$key"]="failed"
    echo "${label}: failed" >&2
  fi
}

declare -A STEP_STATUS=(
  [layered_packages]="pending"
  [flatpaks]="pending"
  [vscode_extensions]="pending"
)

echo "Applying workstation state from: $STATE_DIR"

run_step \
  "layered_packages" \
  "Layered packages" \
  "$STATE_DIR/layered-packages.txt" \
  xargs -r -a "$STATE_DIR/layered-packages.txt" sudo rpm-ostree install

run_step \
  "flatpaks" \
  "Flatpaks" \
  "$STATE_DIR/flatpaks.txt" \
  bash -lc "flatpak remote-add --if-not-exists flathub https://flathub.org/repo/flathub.flatpakrepo && xargs -r -a \"$STATE_DIR/flatpaks.txt\" flatpak install -y flathub"

if command -v code >/dev/null 2>&1; then
  run_step \
    "vscode_extensions" \
    "VS Code extensions" \
    "$STATE_DIR/vscode-extensions.txt" \
    xargs -r -a "$STATE_DIR/vscode-extensions.txt" -n1 code --install-extension
else
  STEP_STATUS["vscode_extensions"]="skipped"
  echo "VS Code extensions: skipped ('code' binary not available)"
fi

echo
echo "State apply summary:"
echo "  - Layered packages: ${STEP_STATUS[layered_packages]}"
echo "  - Flatpaks: ${STEP_STATUS[flatpaks]}"
echo "  - VS Code extensions: ${STEP_STATUS[vscode_extensions]}"
echo
echo "State apply complete."
echo "Reboot recommended if rpm-ostree installed packages."
