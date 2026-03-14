#!/usr/bin/env bash
set -euo pipefail

PROFILE_CONFIG="${RESTICPROFILE_CONFIG:-$HOME/.local/share/backup/restic/profiles.toml}"
PASSWORD_FILE="${RESTIC_PASSWORD_FILE:-$HOME/.config/restic/password}"
ENV_FILE="${RESTIC_ENV_FILE:-$HOME/.config/restic/env}"
STATE_DIR="$HOME/.local/state/backup"

usage() {
  cat <<'EOF'
Usage:
  bootstrap.sh full-restore [snapshot]
  bootstrap.sh restore-home [snapshot]
  bootstrap.sh apply-state

Commands:
  full-restore   Restore HOME from restic, then apply layered packages, Flatpaks, and VS Code extensions.
  restore-home   Only restore HOME from restic.
  apply-state    Only apply state files from ~/.local/state/backup.

Defaults:
  command  = full-restore
  snapshot = latest

Env overrides:
  RESTICPROFILE_CONFIG  Path to profiles.toml
  RESTIC_PASSWORD_FILE  Path to restic password file
  RESTIC_ENV_FILE       Path to env file with S3 credentials
EOF
}

require_file() {
  local file="$1"
  if [[ ! -f "$file" ]]; then
    echo "Required file not found: $file" >&2
    exit 1
  fi
}

repository_from_profile() {
  sed -n 's/^repository = "\(.*\)"/\1/p' "$PROFILE_CONFIG" | head -n1
}

restore_home() {
  local snapshot="${1:-latest}"
  local repository
  local restore_root

  require_file "$PROFILE_CONFIG"
  require_file "$PASSWORD_FILE"
  require_file "$ENV_FILE"

  if ! command -v restic >/dev/null 2>&1; then
    echo "restic binary not found in PATH" >&2
    exit 1
  fi

  repository="$(repository_from_profile)"
  if [[ -z "$repository" ]]; then
    echo "Could not read repository from: $PROFILE_CONFIG" >&2
    exit 1
  fi

  echo "Restoring HOME from repository: $repository"
  echo "Snapshot: $snapshot"

  set -a
  # shellcheck disable=SC1090
  source "$ENV_FILE"
  set +a

  restore_root="$(mktemp -d)"
  echo "Temporary restore root: $restore_root"

  restic \
    -r "$repository" \
    --password-file "$PASSWORD_FILE" \
    restore "$snapshot" \
    --target "$restore_root" \
    --include "$HOME"

  rsync -aHAX --delete "$restore_root/$HOME/" "$HOME/"
  rm -rf "$restore_root"

  echo "HOME restore complete."
}

apply_state() {
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
}

COMMAND="${1:-full-restore}"
SNAPSHOT="${2:-latest}"

case "$COMMAND" in
  full-restore)
    restore_home "$SNAPSHOT"
    apply_state
    ;;
  restore-home)
    restore_home "$SNAPSHOT"
    ;;
  apply-state)
    apply_state
    ;;
  -h|--help|help)
    usage
    ;;
  *)
    echo "Unknown command: $COMMAND" >&2
    usage
    exit 1
    ;;
esac
