#!/usr/bin/env bash
set -euo pipefail

STATE_DIR="$HOME/.local/state/backup"

echo "Applying workstation state from: $STATE_DIR"

if [[ -f "$STATE_DIR/layered-packages.txt" ]] && [[ -s "$STATE_DIR/layered-packages.txt" ]]; then
  echo "Installing layered packages..."
  xargs -r -a "$STATE_DIR/layered-packages.txt" sudo rpm-ostree install
fi

if [[ -f "$STATE_DIR/flatpaks.txt" ]] && [[ -s "$STATE_DIR/flatpaks.txt" ]]; then
  echo "Installing flatpaks..."
  flatpak remote-add --if-not-exists flathub https://flathub.org/repo/flathub.flatpakrepo
  xargs -r -a "$STATE_DIR/flatpaks.txt" flatpak install -y flathub
fi

if [[ -f "$STATE_DIR/vscode-extensions.txt" ]] && [[ -s "$STATE_DIR/vscode-extensions.txt" ]] && command -v code >/dev/null 2>&1; then
  echo "Installing VS Code extensions..."
  xargs -r -a "$STATE_DIR/vscode-extensions.txt" -n1 code --install-extension
fi

echo "State apply complete."
echo "Reboot recommended if rpm-ostree installed packages."
