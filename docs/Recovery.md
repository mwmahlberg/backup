# recovery

Complete recovery path from a freshly installed Fedora Silverblue system to a fully restored workstation.

Assumptions:
- Fedora Silverblue is freshly installed
- network is already configured
- restore credentials are available either from a secure USB device or another secure source

## What you need before starting

- access to the backup repository credentials:
  - `~/.config/restic/password`
  - `~/.config/restic/env`
- or the equivalent values:
  - `RESTIC_REPOSITORY`
  - `AWS_ACCESS_KEY_ID`
  - `AWS_SECRET_ACCESS_KEY`
  - `RESTIC_PASSWORD`
- recommended: a dedicated encrypted USB device or encrypted partition prepared with:

```bash
backup-task backup:save-settings
```

## 1) Rebase Silverblue to the custom image

On a fresh system, `task` is not available yet. Rebase manually:

```bash
sudo rpm-ostree rebase ostree-unverified-registry:docker://docker.io/mwmahlberg/kinoite-workstation:43
sudo systemctl reboot
```

After reboot, the custom image is active and `backup-task` is available.

## 2) Switch to a TTY before restore

Run the destructive restore either:
- from a TTY, for example with `Ctrl`+`Alt`+`F3`
- or before the first graphical login

This avoids desktop processes racing with the restore.

## 3) Optional: restore saved settings from USB

If you previously stored restore-critical files on a USB device, restore them first:

```bash
backup-task backup:restore-settings
```

This is especially useful when the USB device already contains:
- `backup-config/restic/password`
- `backup-config/restic/env`

If the selected partition is encrypted with LUKS, unlock and mount it manually before running the task.

## 4) Alternative: create restore config from environment variables

If you do not use `backup:restore-settings`, create the local restore config directly:

```bash
RESTIC_REPOSITORY=s3:fra1.digitaloceanspaces.com/mwmbackups \
  AWS_ACCESS_KEY_ID=your-access-key \
  AWS_SECRET_ACCESS_KEY=your-secret-key \
  RESTIC_PASSWORD=your-restic-password \
  backup-task restore:init
```

`restore:init` creates:
- `~/.config/restic/password`
- `~/.config/restic/env`
- `~/.config/resticprofile/profiles.toml`

## 5) Validate restore prerequisites

```bash
backup-task restore:check
```

This verifies:
- required binaries are present
- the bundled restic profile exists
- local restic credential files exist
- the repository is reachable
- at least one snapshot is available

## 6) Optional: inspect snapshots

```bash
backup-task restore:list-snapshots
```

To restore a specific snapshot instead of the latest one:

```bash
backup-task restore:snapshot SNAPSHOT=<snapshot-id>
```

## 7) Run the full restore

```bash
backup-task restore:full
```

This restores `$HOME` from the latest snapshot and automatically runs `restore/bootstrap.sh` afterwards.

The bootstrap step re-applies saved workstation state, including:
- layered `rpm-ostree` packages
- Flatpak apps
- VS Code extensions

## 8) Reboot into the restored system

```bash
sudo systemctl reboot
```

## 9) Re-enable backup schedules

After the reboot:

```bash
backup-task system:schedule
```

Optional, if user timers should survive without an active login session:

```bash
loginctl enable-linger "$USER"
```

## 10) Final checks

Verify that the restored system is usable:
- shell config and dotfiles
- project directories
- Flatpaks and desktop apps
- VS Code and extensions
- backup timers

You can inspect the timer state with:

```bash
systemctl --user list-timers '*resticprofile*'
```

## Short version

```bash
sudo rpm-ostree rebase ostree-unverified-registry:docker://docker.io/mwmahlberg/kinoite-workstation:43
sudo systemctl reboot

# switch to a TTY before continuing

# optional:
backup-task backup:restore-settings

# if needed instead of the previous step:
RESTIC_REPOSITORY=s3:fra1.digitaloceanspaces.com/mwmbackups \
  AWS_ACCESS_KEY_ID=your-access-key \
  AWS_SECRET_ACCESS_KEY=your-secret-key \
  RESTIC_PASSWORD=your-restic-password \
  backup-task restore:init

backup-task restore:check
backup-task restore:list-snapshots
backup-task restore:full
sudo systemctl reboot
backup-task system:schedule
```
