# backup
[![Docker](https://img.shields.io/docker/v/mwmahlberg/kinoite-workstation/43?logo=docker&label=docker)](https://hub.docker.com/r/mwmahlberg/kinoite-workstation)
[![Version](https://img.shields.io/github/v/tag/mwmahlberg/backup?sort=semver&label=version)](https://github.com/mwmahlberg/backup/tags)
[![Open Issues](https://img.shields.io/github/issues/mwmahlberg/backup?label=open%20issues)](https://github.com/mwmahlberg/backup/issues)

English docs. Deutsche Version: [README.de.md](README.de.md)

Custom Fedora Kinoite workstation image and reproducible backup/restore workflow using `restic`/`resticprofile`.

## Quickstart (6 commands)

No `git clone` required. The required code is shipped in the image under `/usr/share/backup`.

```bash
backup-task setup:first-boot
backup-task restore:check
backup-task restore:full
sudo systemctl reboot
backup-task system:schedule
backup-task doctor
```

## What this repository contains

| Path                   | Purpose                                                                    |
| ---------------------- | -------------------------------------------------------------------------- |
| `Dockerfile`           | Custom Kinoite image (packages, repos, tools)                              |
| `Taskfile.yml`         | Task automation (`task`) for build, push, rebase, and restore              |
| `restic/profiles.toml` | resticprofile configuration (backup, check, forget, restore)               |
| `restic/hooks/`        | Hooks that export packages, Flatpaks, and VS Code extensions before backup |
| `restore/bootstrap.sh` | Re-applies saved workstation state after restore                           |
| `docs/`                | Detailed guides                                                            |

Generated state files (`~/.local/state/backup/`) are intentionally not stored in git. They are generated during backup and included in snapshots.

---

## ⚠️ What must be stored on USB/offline

These files are **not included in backups** (`~/.config/restic` is explicitly excluded).
Without them, restore is impossible if the machine is lost.
Storing them on a dedicated USB device is optional, but strongly recommended.
Best practice: use an encrypted USB device or encrypted partition and keep `backup-config/`
there via `backup-task backup:save-settings`.

| File                        | Purpose                                                                            |
| --------------------------- | ---------------------------------------------------------------------------------- |
| `~/.config/restic/password` | Password for the restic repository                                                 |
| `~/.config/restic/env`      | S3 credentials (`RESTIC_REPOSITORY`, `AWS_ACCESS_KEY_ID`, `AWS_SECRET_ACCESS_KEY`) |

Example `~/.config/restic/env`:

```bash
RESTIC_REPOSITORY=s3:fra1.digitaloceanspaces.com/mwmbackups
AWS_ACCESS_KEY_ID=your-access-key
AWS_SECRET_ACCESS_KEY=your-secret-key
```

---

## End-to-End Workflow

### 1) Base installation: Fedora Kinoite or Silverblue

Install Fedora Kinoite or Silverblue as usual. After first boot, continue with step 2.

### 2) Rebase to your custom image

On the **very first** rebase, `task` may not be available yet, so run it manually:

```bash
sudo rpm-ostree rebase ostree-unverified-registry:docker://docker.io/mwmahlberg/kinoite-workstation:43
sudo systemctl reboot
```

After reboot, the custom image is active and `task` is available.
All later rebases (for example after a push) can use:

```bash
task system:rebase
```

Details: [docs/kinoite-rebase.md](docs/kinoite-rebase.md)

### 3) Configure backups

Prerequisite: credentials are available (USB drive, password manager, etc.).

Recommended after setup:

```bash
backup-task backup:save-settings
```

No repository checkout is required. The image ships backup code under `/usr/share/backup`,
and `backup-task` uses the Taskfile from there.

One-command setup:

```bash
RESTIC_REPOSITORY=s3:fra1.digitaloceanspaces.com/mwmbackups \
  AWS_ACCESS_KEY_ID=your-access-key \
  AWS_SECRET_ACCESS_KEY=your-secret-key \
  RESTIC_PASSWORD=your-restic-password \
  backup-task setup:first-boot
```

Alternative (only config setup, without repo init and schedule activation):

```bash
backup-task restore:init
```

Details: [docs/backup.md](docs/backup.md)

### 4) Restore on a fresh system

Prerequisite: custom image is active (step 2) and credentials are available.
Run restore from a TTY (`Ctrl`+`Alt`+`F3`) or before first graphical login.

```bash
RESTIC_REPOSITORY=s3:fra1.digitaloceanspaces.com/mwmbackups \
  AWS_ACCESS_KEY_ID=your-access-key \
  AWS_SECRET_ACCESS_KEY=your-secret-key \
  RESTIC_PASSWORD=your-restic-password \
  backup-task restore:init

backup-task restore:check
# optional: inspect available snapshots first
backup-task restore:list-snapshots
backup-task restore:full
```

After restore:

```bash
sudo systemctl reboot
# after reboot:
backup-task system:schedule
```

Details: [docs/restore.md](docs/restore.md)

---

## Available Tasks

`backup-task help` shows the guided entrypoint.

| Task                | Description                                          |
| ------------------- | ---------------------------------------------------- |
| `help`              | Guided entrypoint for common workflows               |
| `doctor`            | Validate prerequisites                               |
| `secrets:setup`     | Create restic secret files                           |
| `secrets:check`     | Validate presence/permissions of restic secret files |
| `setup:first-boot`  | One-command first-boot setup                         |
| `restore:init`      | Create restic config from env vars                   |
| `restore:check`     | Validate restore prerequisites and snapshot access   |
| `restore:list-snapshots` | List available snapshots before restore         |
| `restore:snapshot`  | Restore a specific snapshot ID                       |
| `restore:full`      | Full restore with next-step hints                    |
| `restore:bootstrap` | Manually re-apply workstation state                  |
| `system:schedule`   | Re-enable backup schedules after restore             |

---

## Detailed Documentation

- [docs/backup.md](docs/backup.md) - Backup workflow in detail
- [docs/restore.md](docs/restore.md) - Restore workflow in detail
- [docs/Recovery.md](docs/Recovery.md) - Full recovery from fresh Silverblue to restored system
- [docs/kinoite-rebase.md](docs/kinoite-rebase.md) - Build, push, and rebase workflow

## Automatic System Updates (in-system)

For unattended updates on Kinoite, use a moving image tag and enable `rpm-ostree` automatic staging.

Switch to your desired update channel:

```bash
# stable channel (main builds)
task system:channel:stable

# dev channel (develop builds)
task system:channel:dev

sudo systemctl reboot
```

Enable automatic staged updates:

```bash
task system:auto-update:enable
```

Check status anytime:

```bash
task system:auto-update:status
```

## Git-Flow Release Workflow

Release automation is split into two stages to match `git-flow`:

1. Push to `release/vX.Y.Z` (or `release/X.Y.Z`) and `hotfix/vX.Y.Z` (or `hotfix/X.Y.Z`): CI validates the branch, generates `CHANGELOG.md` and `releaselog.md` from Conventional Commits, and commits both files back to the same branch.
2. Finish the branch (`git flow release finish vX.Y.Z` or `git flow hotfix finish vX.Y.Z`) and push tags: CI only creates/updates a GitHub Release for `vX.Y.Z`.

The GitHub Release intentionally has no artifacts and contains only a link to the versioned README:

`https://github.com/mwmahlberg/backup/blob/vX.Y.Z/README.md`
