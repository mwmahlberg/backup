#!/usr/bin/env bash
set -euo pipefail

SOURCE_DIR="${BACKUP_SOURCE_DIR:-/usr/share/backup}"
TARGET_DIR="${1:-$HOME/.local/share/backup}"

if [[ ! -d "$SOURCE_DIR" ]]; then
    echo "Backup source directory not found: $SOURCE_DIR" >&2
    exit 1
fi

mkdir -p "$TARGET_DIR"
for item in Taskfile.yml restic restore README.md README.de.md docs; do
    if [[ -e "$SOURCE_DIR/$item" ]]; then
        cp -a "$SOURCE_DIR/$item" "$TARGET_DIR"/
    fi
done

chmod 0755 "$TARGET_DIR"/restic/hooks/*.sh "$TARGET_DIR"/restore/bootstrap.sh 2>/dev/null || true

echo "Backup files seeded at: $TARGET_DIR"
if [[ ! -f "$TARGET_DIR/restic/profiles.toml" ]]; then
    echo "Missing $TARGET_DIR/restic/profiles.toml after copy; please verify image content."
fi
echo "Run 'backup-task setup:first-boot' or 'task restore:init' next."
