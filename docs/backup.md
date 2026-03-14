# backup

Detailed backup workflow for this repository.

## Overview

Backups are managed through `resticprofile` using `restic/profiles.toml`.
The default profile:

- backs up the full home directory (`$HOME`)
- excludes common cache/build paths
- exports restore state files before backup
- pauses all running podman containers before backup and unpauses them after
- applies retention policy (`forget + prune`)

## Prerequisites

- `restic` installed and available in `PATH`
- `resticprofile` installed and available in `PATH`
- `jq` installed (required by `export-layered-packages.sh`)
- `podman`, `flatpak` and optionally `code` available for hook/state capture
- `~/.config/restic/password` present
- `~/.config/restic/env` present with credentials

Example env file:

```bash
AWS_ACCESS_KEY_ID=...
AWS_SECRET_ACCESS_KEY=...
```

## Profile behavior

Profile file: `restic/profiles.toml`

- `repository` points to S3-compatible storage
- `password-file` and `env-file` are resolved from `$HOME/.config/restic/`
- `run-before`:
  - pauses podman containers
  - exports layered packages, flatpaks, and VS Code extensions to `~/.local/state/backup/`
- `run-finally` unpauses podman containers
- backup includes `$HOME` with exclusions
- backup uses max compression and one filesystem mode
- check and forget schedules are defined in profile

## Initialize repository

Run once per new repository:

```bash
resticprofile -c ~/.local/share/backup/restic/profiles.toml init
```

## Manual operations

Run backup:

```bash
resticprofile -c ~/.local/share/backup/restic/profiles.toml backup
```

Run consistency check:

```bash
resticprofile -c ~/.local/share/backup/restic/profiles.toml check
```

Run retention/cleanup:

```bash
resticprofile -c ~/.local/share/backup/restic/profiles.toml forget
```

List snapshots:

```bash
set -a
source ~/.config/restic/env
set +a
restic -r "$(sed -n 's/^repository = "\(.*\)"/\1/p' ~/.local/share/backup/restic/profiles.toml | head -n1)" \
  --password-file ~/.config/restic/password snapshots
```

## Scheduling with systemd user units

`resticprofile` can generate/install systemd user units from schedules in `profiles.toml`:

```bash
resticprofile -c ~/.local/share/backup/restic/profiles.toml schedule --all --start --reload
systemctl --user list-timers '*resticprofile*'
```

Remove generated schedules:

```bash
resticprofile -c ~/.local/share/backup/restic/profiles.toml unschedule --all
```

If you want timers to run without active login:

```bash
loginctl enable-linger "$USER"
```

## Hook-generated restore state

The following files are generated on backup and included in snapshots:

- `~/.local/state/backup/layered-packages.txt`
- `~/.local/state/backup/flatpaks.txt`
- `~/.local/state/backup/vscode-extensions.txt`

These are consumed by `restore/bootstrap.sh apply-state` during restore.

## Troubleshooting

No repository access / auth errors:

- verify `~/.config/restic/env` is present and valid
- verify `~/.config/restic/password` is correct
- test with `restic snapshots`

Backup hangs or fails around containers:

- check podman health: `podman ps -a`
- run backup with verbose logs: `resticprofile -v -c ~/.local/share/backup/restic/profiles.toml backup`

Missing state files:

- run hooks manually from `restic/hooks/`
- confirm `jq` is installed for layered package export
