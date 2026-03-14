# restore

Restore guide for a freshly installed Fedora Silverblue system with no tools and no restic config present.

Note: commands below use `restic` and `resticprofile` directly because `~/.local/bin` is in `PATH` by default on Fedora Silverblue.

## Goal

Restore full `$HOME` from restic and then re-apply workstation state:

- layered `rpm-ostree` packages
- Flatpak apps
- VS Code extensions

Restore is now handled directly by `resticprofile` restore settings in `restic/profiles.toml` (`[default.restore]`), including:

- `target = "/"`
- `path = true`
- `host = true`
- `delete = true`
- `run-after = "$HOME/.local/share/backup/restore/bootstrap.sh"`

## Important warning

You must have the restic password available from a different machine or secure offline storage.
Without `~/.config/restic/password`, restore is not possible.

## Safety first

Run restore from a TTY (`Ctrl`+`Alt`+`F3`) or before first graphical login.
`restore` uses restic `--delete` (configured in `[default.restore]`), so your live `$HOME` will be made to match the selected snapshot.

## Quickstart (one-screen checklist)

Use this if you already know what each step does and want the shortest path.

1. Install base packages, then reboot.

	```bash
	sudo rpm-ostree install git curl jq rsync bzip2 tar
	systemctl reboot
	```

2. Clone the repository.

	```bash
	git clone https://github.com/mwmahlberg/backup.git ~/.local/share/backup
	```

3. Install latest `restic` and `resticprofile`.

	```bash
	mkdir -p ~/.local/bin /tmp/backup-install
	RESTIC_VERSION="$(curl -fsSL https://api.github.com/repos/restic/restic/releases/latest | sed -n 's/.*"tag_name": "\([^"]*\)".*/\1/p' | head -n1)"
	curl -fsSL "https://github.com/restic/restic/releases/download/${RESTIC_VERSION}/restic_${RESTIC_VERSION#v}_linux_amd64.bz2" | bzip2 -d > ~/.local/bin/restic
	chmod +x ~/.local/bin/restic
	RESTICPROFILE_VERSION="$(curl -fsSL https://api.github.com/repos/creativeprojects/resticprofile/releases/latest | sed -n 's/.*"tag_name": "\([^"]*\)".*/\1/p' | head -n1)"
	curl -fsSL "https://github.com/creativeprojects/resticprofile/releases/download/${RESTICPROFILE_VERSION}/resticprofile_${RESTICPROFILE_VERSION#v}_linux_amd64.tar.gz" -o /tmp/backup-install/resticprofile.tar.gz
	tar -xzf /tmp/backup-install/resticprofile.tar.gz -C /tmp/backup-install resticprofile
	install -m 0755 /tmp/backup-install/resticprofile ~/.local/bin/resticprofile
	```

4. Create restic secrets and lock down permissions.

	```bash
	mkdir -p ~/.config/restic
	cat > ~/.config/restic/password <<'EOF'
	your-very-secret-restic-password
	EOF
	chmod 600 ~/.config/restic/password
	```

	```bash
	cat > ~/.config/restic/env <<'EOF'
	AWS_ACCESS_KEY_ID=your-access-key
	AWS_SECRET_ACCESS_KEY=your-secret-key
	EOF
	chmod 600 ~/.config/restic/env
	```

5. Restore full HOME from latest snapshot.

	```bash
	resticprofile -c ~/.local/share/backup/restic/profiles.toml restore latest
	```

6. Re-enable backup schedules.

	```bash
	resticprofile -c ~/.local/share/backup/restic/profiles.toml schedule --all --start --reload
	```

## Step-by-step from a naked system

### 1) Install base packages

Example:

```bash
sudo rpm-ostree install git curl jq rsync bzip2 tar
systemctl reboot
```

### 2) Clone this repository

Example:

```bash
git clone https://github.com/mwmahlberg/backup.git ~/.local/share/backup
```

### 3) Install latest `restic` and `resticprofile`

Example:

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

### 4) Create restic config files

Create directories:

```bash
mkdir -p ~/.config/restic
```

Create password file (example):

```bash
cat > ~/.config/restic/password <<'EOF'
your-very-secret-restic-password
EOF
chmod 600 ~/.config/restic/password
```

Create env file (example for S3-compatible storage):

```bash
cat > ~/.config/restic/env <<'EOF'
AWS_ACCESS_KEY_ID=your-access-key
AWS_SECRET_ACCESS_KEY=your-secret-key
EOF
chmod 600 ~/.config/restic/env
```

### 5) Verify tools and repository access

Example:

```bash
restic version
resticprofile version

set -a
source ~/.config/restic/env
set +a

restic \
	-r "$(sed -n 's/^repository = "\(.*\)"/\1/p' ~/.local/share/backup/restic/profiles.toml | head -n1)" \
	--password-file ~/.config/restic/password \
	snapshots
```

### 6) Run full restore

Restore latest snapshot (example):

```bash
resticprofile -c ~/.local/share/backup/restic/profiles.toml restore latest
```

Restore a specific snapshot ID (example):

```bash
resticprofile -c ~/.local/share/backup/restic/profiles.toml restore 70e69674
```

`restore/bootstrap.sh` is executed automatically via `[default.restore].run-after` after a successful restore.

### 7) Reboot and verify

Example:

```bash
systemctl reboot
```

After reboot, verify key applications, shell config, dotfiles, and project directories.

### 8) Re-enable backup schedules

Example:

```bash
resticprofile -c ~/.local/share/backup/restic/profiles.toml schedule --all --start --reload
systemctl --user list-timers '*resticprofile*'
```

Optional for timers without active login:

```bash
loginctl enable-linger "$USER"
```

## Apply-state helper

`restore/bootstrap.sh` can still be run manually if you need to re-apply state later.

```bash
bash ~/.local/share/backup/restore/bootstrap.sh
```

## State files used by apply-state

- `~/.local/state/backup/layered-packages.txt`
- `~/.local/state/backup/flatpaks.txt`
- `~/.local/state/backup/vscode-extensions.txt`
