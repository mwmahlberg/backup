# backup

English docs. Deutsche Version: [README.de.md](README.de.md)

Custom Fedora Kinoite workstation image and reproducible backup/restore workflow using `restic`/`resticprofile`.

## Quickstart (5 commands)

No `git clone` required. The required code is shipped in the image under `/usr/share/backup`.

```bash
backup-task setup:first-boot
backup-task restore:full
sudo systemctl reboot
backup-task restore:schedule
backup-task doctor
```

## What this repository contains

| Path                    | Purpose                                                                    |
| ----------------------- | -------------------------------------------------------------------------- |
| `Containerfile.kinoite` | Custom Kinoite image (packages, repos, tools)                              |
| `Taskfile.yml`          | Task automation (`task`) for build, push, rebase, and restore              |
| `restic/profiles.toml`  | resticprofile configuration (backup, check, forget, restore)               |
| `restic/hooks/`         | Hooks that export packages, Flatpaks, and VS Code extensions before backup |
| `restore/bootstrap.sh`  | Re-applies saved workstation state after restore                           |
| `docs/`                 | Detailed guides                                                            |

Generated state files (`~/.local/state/backup/`) are intentionally not stored in git. They are generated during backup and included in snapshots.

---

## ⚠️ What must be stored on USB/offline

These files are **not included in backups** (`~/.config/restic` is explicitly excluded).
Without them, restore is impossible if the machine is lost.

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

### 1) Base installation: Fedora Kinoite

Install Fedora Kinoite as usual. After first boot, continue with step 2.

### 2) Rebase to your custom image

On the **very first** rebase, `task` may not be available yet, so run it manually:

```bash
sudo rpm-ostree rebase ostree-unverified-registry:docker.io/mwmahlberg/kinoite-workstation:latest
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

Alternative (interactive):

```bash
backup-task restore:init:interactive
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

backup-task restore:full
```

After restore:

```bash
sudo systemctl reboot
# after reboot:
backup-task restore:schedule
```

Details: [docs/restore.md](docs/restore.md)

---

## Available Tasks

`backup-task help` shows the guided entrypoint.

| Task                       | Description                                                   |
| -------------------------- | ------------------------------------------------------------- |
| `help`                     | Guided entrypoint for common workflows                        |
| `doctor`                   | Validate prerequisites                                        |
| `secrets:check`            | Validate presence/permissions of restic secret files          |
| `backup:seed`              | Copy bundled code from `/usr/share/backup` to user directory  |
| `setup:first-boot`         | One-command first-boot setup                                  |
| `restore:init`             | Create restic config from env vars                            |
| `restore:init:interactive` | Create restic config interactively                            |
| `restore:full`             | Full restore with next-step hints                             |
| `restore:bootstrap`        | Manually re-apply workstation state                           |
| `restore:schedule`         | Re-enable backup schedules after restore                      |

---

## Detailed Documentation

- [docs/backup.md](docs/backup.md) - Backup workflow in detail
- [docs/restore.md](docs/restore.md) - Restore workflow in detail
- [docs/kinoite-rebase.md](docs/kinoite-rebase.md) - Build, push, and rebase workflow
