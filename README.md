# backup

Reproducible workstation backup for Fedora Silverblue.

## Components

- `restic`
- `resticprofile`
- DigitalOcean Spaces (S3-compatible)

## Repository Scope

This repository contains only:

- backup configuration
- hook scripts
- restore logic
- documentation

Generated state files are not stored in git. They are written to `~/.local/state/backup/` and backed up by restic.

## Clone Location

```bash
git clone https://github.com/mwmahlberg/backup.git ~/.local/share/backup
```

## Install restic and resticprofile

The commands below download the latest Linux `x86_64` releases from GitHub and install them into `~/.local/bin`.
If you are on another architecture, replace `linux_amd64` with the correct target.

### Install latest restic

```bash
mkdir -p ~/.local/bin /tmp/backup-install
RESTIC_VERSION="$(curl -fsSL https://api.github.com/repos/restic/restic/releases/latest | sed -n 's/.*"tag_name": "\([^"]*\)".*/\1/p' | head -n1)"
curl -fsSL "https://github.com/restic/restic/releases/download/${RESTIC_VERSION}/restic_${RESTIC_VERSION#v}_linux_amd64.bz2" \
  | bzip2 -d \
  > ~/.local/bin/restic
chmod +x ~/.local/bin/restic
```

### Install latest resticprofile

```bash
RESTICPROFILE_VERSION="$(curl -fsSL https://api.github.com/repos/creativeprojects/resticprofile/releases/latest | sed -n 's/.*"tag_name": "\([^"]*\)".*/\1/p' | head -n1)"
curl -fsSL "https://github.com/creativeprojects/resticprofile/releases/download/${RESTICPROFILE_VERSION}/resticprofile_${RESTICPROFILE_VERSION#v}_linux_amd64.tar.gz" \
  -o /tmp/backup-install/resticprofile.tar.gz
tar -xzf /tmp/backup-install/resticprofile.tar.gz -C /tmp/backup-install resticprofile
install -m 0755 /tmp/backup-install/resticprofile ~/.local/bin/resticprofile
```

### Verify binaries

```bash
~/.local/bin/restic version
~/.local/bin/resticprofile version
```

## Configure Secrets

Set real values in `~/.local/share/backup/restic/profiles.toml`, then create:

- `~/.config/restic/password`
- `~/.config/restic/env`

`~/.config/restic/env` should contain S3 credentials, for example:

```bash
AWS_ACCESS_KEY_ID=...
AWS_SECRET_ACCESS_KEY=...
```

## Initialize Repository

```bash
~/.local/bin/resticprofile -c ~/.local/share/backup/restic/profiles.toml init
```

## Run Backups Manually

```bash
~/.local/bin/resticprofile -c ~/.local/share/backup/restic/profiles.toml backup
~/.local/bin/resticprofile -c ~/.local/share/backup/restic/profiles.toml forget
```

## Systemd User Units

The repository ships `resticprofile` user units in `restic/`:

- `resticprofile-backup.service`
- `resticprofile-backup.timer`
- `resticprofile-forget.service`
- `resticprofile-forget.timer`

Install and enable them:

```bash
mkdir -p ~/.config/systemd/user
install -m 0644 ~/.local/share/backup/restic/resticprofile-backup.service ~/.config/systemd/user/
install -m 0644 ~/.local/share/backup/restic/resticprofile-backup.timer ~/.config/systemd/user/
install -m 0644 ~/.local/share/backup/restic/resticprofile-forget.service ~/.config/systemd/user/
install -m 0644 ~/.local/share/backup/restic/resticprofile-forget.timer ~/.config/systemd/user/

systemctl --user daemon-reload
systemctl --user enable --now resticprofile-backup.timer
systemctl --user enable --now resticprofile-forget.timer

# Optional: keep user timers running without an active login session.
loginctl enable-linger "$USER"
```

Inspect status and logs:

```bash
systemctl --user list-timers 'resticprofile-*'
systemctl --user status resticprofile-backup.service
journalctl --user -u resticprofile-backup.service -n 100 --no-pager
```
