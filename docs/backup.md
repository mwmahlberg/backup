# backup

Detailed backup workflow for this repository.

## Overview

Backups are managed with `resticprofile` using `restic/profiles.toml`.
The default profile:

- backs up the full home directory (`$HOME`)
- excludes cache/build and container storage paths
- exports workstation state files before each backup
- pauses running Podman containers before backup and unpauses them afterwards
- applies a retention policy (`forget + prune`)

## Prerequisites

- Custom Kinoite image is active (`restic`, `resticprofile`, and `task` are already included)
- Bundled backup code is available under `/usr/share/backup` (accessible via `backup-task`)
- `~/.config/restic/password` exists
- `~/.config/restic/env` exists with S3 credentials

Example `~/.config/restic/env`:

```bash
RESTIC_REPOSITORY=s3:fra1.digitaloceanspaces.com/mwmbackups
AWS_ACCESS_KEY_ID=your-access-key
AWS_SECRET_ACCESS_KEY=your-secret-key
```

Create config automatically:

```bash
RESTIC_REPOSITORY=... AWS_ACCESS_KEY_ID=... AWS_SECRET_ACCESS_KEY=... RESTIC_PASSWORD=... \
  backup-task setup:first-boot
```

## Profile Behavior

Profile file: `restic/profiles.toml`

- `repository` points to S3-compatible storage
- `password-file` and `env-file` are loaded from `$HOME/.config/restic/`
- `run-before`:
  - pauses Podman containers
  - exports layered packages, Flatpaks, and VS Code extensions to `~/.local/state/backup/`
- `run-finally` unpauses Podman containers
- backup includes `$HOME` (with exclusions)
- max compression and single-filesystem mode

## Initialize Repository (one-time)

```bash
resticprofile -c ~/.local/share/backup/restic/profiles.toml init
```

## Manual Operations

Run backup:

```bash
resticprofile -c ~/.local/share/backup/restic/profiles.toml backup
```

Run consistency check:

```bash
resticprofile -c ~/.local/share/backup/restic/profiles.toml check
```

Apply retention policy:

```bash
resticprofile -c ~/.local/share/backup/restic/profiles.toml forget
```

List snapshots:

```bash
set -a; source ~/.config/restic/env; set +a
restic -r "$RESTIC_REPOSITORY" --password-file ~/.config/restic/password snapshots
```

## Schedules (systemd user units)

Enable schedules (after initial setup or after restore):

```bash
backup-task system:schedule
```

Directly via `resticprofile`:

```bash
resticprofile -c ~/.local/share/backup/restic/profiles.toml schedule --all --start --reload
systemctl --user list-timers '*resticprofile*'
```

Logs and units:

```bash
journalctl --user -n 200 --no-pager | grep -i resticprofile
systemctl --user list-unit-files | grep -i resticprofile
```

Remove schedules:

```bash
resticprofile -c ~/.local/share/backup/restic/profiles.toml unschedule --all
```

Allow timers without an active login session:

```bash
loginctl enable-linger "$USER"
```

## Hook-Generated State Files

These files are generated before each backup and included in snapshots:

| File                                          | Purpose                     |
| --------------------------------------------- | --------------------------- |
| `~/.local/state/backup/layered-packages.txt`  | layered rpm-ostree packages |
| `~/.local/state/backup/flatpaks.txt`          | installed Flatpak apps      |
| `~/.local/state/backup/vscode-extensions.txt` | VS Code extensions          |

## Troubleshooting

No repository access / auth errors:
- verify `~/.config/restic/env`
- verify `~/.config/restic/password`
- test manually with `restic snapshots`

Backup hangs or fails around containers:
- check Podman status: `podman ps -a`
- run with verbose output: `resticprofile -v -c ~/.local/share/backup/restic/profiles.toml backup`

Missing state files:
- run hooks manually from `restic/hooks/`
