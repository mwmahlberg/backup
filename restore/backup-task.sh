#!/usr/bin/env bash
set -euo pipefail

exec /usr/bin/task -t /usr/share/backup/Taskfile.yml "$@"
