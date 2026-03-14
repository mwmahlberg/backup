# backup

Reproducible workstation backup for Fedora Silverblue.

## What this repository contains

- `restic/` configuration (`profiles.toml`) and backup hooks
- `restore/` bootstrap restore helper
- `docs/` restore notes

Generated workstation state files are intentionally not stored in git. They are generated under `~/.local/state/backup/` and included in backups.

## Tooling used

- `restic`
- `resticprofile`
- DigitalOcean Spaces (S3-compatible storage)
- `jq` (used by backup hooks)

## Clone location

```bash
git clone https://github.com/mwmahlberg/backup.git ~/.local/share/backup
```

## Detailed documentation

- Backup guide: `docs/backup.md`
- Restore guide: `docs/restore.md`

## Install required tools

### 1) Install OS package dependency (`jq`)

```bash
sudo rpm-ostree install jq
systemctl reboot
```

### 2) Install latest `restic` and `resticprofile`

The commands below install Linux `x86_64` binaries from GitHub Releases into `~/.local/bin`.
If your architecture is different, replace `linux_amd64` with the correct target.

```bash
mkdir -p ~/.local/bin /tmp/backup-install

RESTIC_VERSION="$(curl -fsSL https://api.github.com/repos/restic/restic/releases/latest | sed -n 's/.*"tag_name": "\([^"]*\)".*/\1/p' | head -n1)"
curl -fsSL "https://github.com/restic/restic/releases/download/${RESTIC_VERSION}/restic_${RESTIC_VERSION#v}_linux_amd64.bz2" \
  | bzip2 -d \
  > ~/.local/bin/restic
chmod +x ~/.local/bin/restic

RESTICPROFILE_VERSION="$(curl -fsSL https://api.github.com/repos/creativeprojects/resticprofile/releases/latest | sed -n 's/.*"tag_name": "\([^"]*\)".*/\1/p' | head -n1)"
curl -fsSL "https://github.com/creativeprojects/resticprofile/releases/download/${RESTICPROFILE_VERSION}/resticprofile_${RESTICPROFILE_VERSION#v}_linux_amd64.tar.gz" \
  -o /tmp/backup-install/resticprofile.tar.gz
tar -xzf /tmp/backup-install/resticprofile.tar.gz -C /tmp/backup-install resticprofile
install -m 0755 /tmp/backup-install/resticprofile ~/.local/bin/resticprofile
```

### 3) Verify installation

```bash
~/.local/bin/restic version
~/.local/bin/resticprofile version
command -v jq podman flatpak
```

## Configure backup profile and secrets

1. Review `~/.local/share/backup/restic/profiles.toml`.
2. Create `~/.config/restic/password` with your repository password.
3. Create `~/.config/restic/env` with your S3 credentials.

Important: `~/.config/restic/password` must be stored on a different machine (or another secure offline location). If the backed-up machine is lost, you still need that password to restore.

Example `~/.config/restic/env`:

```bash
AWS_ACCESS_KEY_ID=...
AWS_SECRET_ACCESS_KEY=...
```

## Initialize and run manually

```bash
~/.local/bin/resticprofile -c ~/.local/share/backup/restic/profiles.toml init
~/.local/bin/resticprofile -c ~/.local/share/backup/restic/profiles.toml backup
~/.local/bin/resticprofile -c ~/.local/share/backup/restic/profiles.toml check
~/.local/bin/resticprofile -c ~/.local/share/backup/restic/profiles.toml forget
```

## Systemd user units (managed by resticprofile)

Scheduling is defined directly in `restic/profiles.toml` (`default.backup`, `default.check`, `default.forget`).
Use `resticprofile schedule` to install systemd user units from that config.

```bash
~/.local/bin/resticprofile -c ~/.local/share/backup/restic/profiles.toml schedule --all --start --reload
systemctl --user list-timers '*resticprofile*'
```

Inspect generated units and recent logs:

```bash
systemctl --user list-unit-files | grep -i resticprofile
systemctl --user list-units --type=service --all | grep -i resticprofile
journalctl --user -n 200 --no-pager | grep -i resticprofile
```

Remove scheduled units again:

```bash
~/.local/bin/resticprofile -c ~/.local/share/backup/restic/profiles.toml unschedule --all
```

Optional, if you want user timers to run without an active graphical/session login:

```bash
loginctl enable-linger "$USER"
```

## Restore on a vanilla Silverblue system (basic config already done)

For full details and additional troubleshooting, see `docs/restore.md`.

This section assumes the target machine already has:

- network and S3 access
- `~/.config/restic/password`
- `~/.config/restic/env`

### 1) Clone repo and install tools

```bash
git clone https://github.com/mwmahlberg/backup.git ~/.local/share/backup
# Then run the install steps above for jq/restic/resticprofile.
```

### 2) Restore complete home directory from snapshot

Run this from a TTY (for example `Ctrl`+`Alt`+`F3`) or before first graphical login on a fresh install, so running desktop processes do not overwrite restored files.

```bash
# Optional: inspect snapshots first.
# ~/.local/bin/restic -r "$(sed -n 's/^repository = "\(.*\)"/\1/p' ~/.local/share/backup/restic/profiles.toml | head -n1)" \
#   --password-file ~/.config/restic/password snapshots

# Full restore with latest snapshot:
bash ~/.local/share/backup/restore/bootstrap.sh full-restore

# Or restore a specific snapshot:
bash ~/.local/share/backup/restore/bootstrap.sh full-restore <snapshot-id>
```

This restores the full home tree, including dotfiles and user data.

### 3) Re-apply layered packages, Flatpaks, and VS Code extensions

```bash
# Included automatically in `full-restore`.
# Run this only if you already restored HOME and only want to apply state.
bash ~/.local/share/backup/restore/bootstrap.sh apply-state
```

If `rpm-ostree` layered packages were installed, reboot afterwards.
