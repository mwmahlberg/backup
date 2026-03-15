#!/usr/bin/env bash
set -euo pipefail

TARGET_DIR="${1:-$HOME/.local/share/backup}"
REPO_URL="${BACKUP_REPO_URL:-https://github.com/mwmahlberg/backup.git}"

if ! command -v git >/dev/null 2>&1; then
    echo "git is required but not installed" >&2
    exit 1
fi

if [[ -d "$TARGET_DIR/.git" ]]; then
    git -C "$TARGET_DIR" pull --ff-only
else
    if [[ -d "$TARGET_DIR" ]] && [[ -n "$(ls -A "$TARGET_DIR" 2>/dev/null)" ]]; then
        echo "Target directory exists and is not a git repo: $TARGET_DIR" >&2
        exit 1
    fi
    mkdir -p "$(dirname "$TARGET_DIR")"
    git clone "$REPO_URL" "$TARGET_DIR"
fi

chmod 0755 "$TARGET_DIR"/restic/hooks/*.sh "$TARGET_DIR"/restore/bootstrap.sh 2>/dev/null || true

echo "Backup repository ready at: $TARGET_DIR"
if [[ ! -f "$TARGET_DIR/restic/profiles.toml" ]]; then
    echo "Create $TARGET_DIR/restic/profiles.toml when you are ready."
fi
echo "Restore runs with restic directly; profiles can be added later."
