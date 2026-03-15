#!/usr/bin/env bash
set -euo pipefail

exec /usr/bin/task --interactive -t /usr/share/backup/Taskfile.yml "$@"
