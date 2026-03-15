# backup

English docs. Deutsche Version: [README.de.md](README.de.md)

Custom Fedora Kinoite workstation image and reproducible backup/restore workflow using `restic`/`resticprofile`.

## What this repository contains

| Path | Purpose |
| --- | --- |
| `Containerfile.kinoite` | Custom Kinoite image (packages, repos, tools) |
| `Taskfile.yml` | Task automation (`task`) for build, push, rebase, and restore |
| `restic/profiles.toml` | resticprofile configuration (backup, check, forget, restore) |
| `restic/hooks/` | Hooks that export packages, Flatpaks, and VS Code extensions before backup |
| `restore/bootstrap.sh` | Re-applies saved workstation state after restore |
| `docs/` | Detailed guides |

Generated state files (`~/.local/state/backup/`) are intentionally not stored in git. They are generated during backup and included in snapshots.

---

## ⚠️ What must be stored on USB/offline

These files are **not included in backups** (`~/.config/restic` is explicitly excluded).
Without them, restore is impossible if the machine is lost.

| File | Purpose |
| --- | --- |
| `~/.config/restic/password` | Password for the restic repository |
| `~/.config/restic/env` | S3 credentials (`RESTIC_REPOSITORY`, `AWS_ACCESS_KEY_ID`, `AWS_SECRET_ACCESS_KEY`) |

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

Clone this repository:

```bash
git clone https://github.com/mwmahlberg/backup.git ~/.local/share/backup
cd ~/.local/share/backup
```

Initialize configuration (pass credentials as environment variables):

```bash
RESTIC_REPOSITORY=s3:fra1.digitaloceanspaces.com/mwmbackups \
  AWS_ACCESS_KEY_ID=your-access-key \
  AWS_SECRET_ACCESS_KEY=your-secret-key \
  RESTIC_PASSWORD=your-restic-password \
  task restore:init
```

Initialize repository (one-time only):

```bash
resticprofile -c ~/.local/share/backup/restic/profiles.toml init
```

Enable backup schedules (systemd user units):

```bash
task restore:schedule
```

Details: [docs/backup.md](docs/backup.md)

### 4) Restore on a fresh system

Prerequisite: custom image is active (step 2) and credentials are available.
Run restore from a TTY (`Ctrl`+`Alt`+`F3`) or before first graphical login.

```bash
git clone https://github.com/mwmahlberg/backup.git ~/.local/share/backup
cd ~/.local/share/backup

RESTIC_REPOSITORY=s3:fra1.digitaloceanspaces.com/mwmbackups \
  AWS_ACCESS_KEY_ID=your-access-key \
  AWS_SECRET_ACCESS_KEY=your-secret-key \
  RESTIC_PASSWORD=your-restic-password \
  task restore:init

task restore:run
```

After restore:

```bash
sudo systemctl reboot
# after reboot:
task restore:schedule
```

Details: [docs/restore.md](docs/restore.md)

---

## Available Tasks

```bash
task --list
```

| Task | Description |
| --- | --- |
| `image:build` | Build Kinoite image locally |
| `image:push` | Push image to registry (builds if needed, logs in first) |
| `image:digest` | Print remote image digest |
| `system:rebase` | Rebase system to current image digest |
| `registry:login` | Log in to container registry |
| `registry:logout` | Log out from container registry |
| `ostree:login` | Configure ostree auth (`/etc/ostree/auth.json`) |
| `ostree:logout` | Remove registry from ostree auth |
| `restore:init` | Create restic config on fresh system |
| `restore:run` | Restore HOME from latest snapshot |
| `restore:bootstrap` | Manually re-apply workstation state |
| `restore:schedule` | Re-enable backup schedules after restore |

---

## Detailed Documentation

- [docs/backup.md](docs/backup.md) - Backup workflow in detail
- [docs/restore.md](docs/restore.md) - Restore workflow in detail
- [docs/kinoite-rebase.md](docs/kinoite-rebase.md) - Build, push, and rebase workflow
