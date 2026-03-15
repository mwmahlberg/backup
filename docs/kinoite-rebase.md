# kinoite rebase

Build, push, and apply a custom Kinoite image on target systems.

The custom image complements home backup with `restic`: it restores the system layer (`/usr`) while restic restores `$HOME`.

## 1) Adjust the Dockerfile

`Dockerfile` in the repository root contains all packages, repos, and tools.

Notes:
- match Fedora release (`:43`, etc.) to your target hosts
- keep the image focused on system packages and system config; user data belongs in restic
- RPM Fusion and the VS Code repo are enabled during build

## 2) Build and push image

```bash
task image:push
```

`image:push` rebuilds automatically when needed (source tracking on `Dockerfile`) and logs in first.

Manual equivalent (without task):

```bash
podman build -t docker.io/mwmahlberg/kinoite-workstation:43 -f Dockerfile .
podman push docker.io/mwmahlberg/kinoite-workstation:43
```

## 3) Sign image (planned)

Generate a key pair once (store private key securely):

```bash
cosign generate-key-pair
```

Sign pushed image:

```bash
cosign sign --key cosign.key docker.io/mwmahlberg/kinoite-workstation:43
```

Verify signature:

```bash
cosign verify --key cosign.pub docker.io/mwmahlberg/kinoite-workstation:43
```

> **Note:** Once signing is enabled, the `system:rebase` task should switch TARGET prefix
> from `ostree-unverified-registry:` to `ostree-image-signed:docker://`.

## 4) First rebase (manual)

On the first rebase, the starting base can be Fedora Kinoite or Silverblue.
`task` may not be available yet, so use `rpm-ostree` directly:

```bash
sudo rpm-ostree rebase ostree-unverified-registry:docker.io/mwmahlberg/kinoite-workstation:43
sudo systemctl reboot
```

After reboot, the custom image is active and `task` is available.

Check status:

```bash
rpm-ostree status
```

## 5) Follow-up rebases

After every new image push:

```bash
task system:rebase
```

`system:rebase` resolves the current remote digest with `skopeo` and prompts for confirmation before rebasing.

### Optional: In-system automatic updates

If you want the host to pull updates automatically, rebase once to a moving channel tag and enable
`rpm-ostree` automatic staging:

```bash
# stable channel (tracks main builds)
task system:channel:stable

# or dev channel (tracks develop builds)
# task system:channel:dev

sudo systemctl reboot
task system:auto-update:enable
```

The status can be checked with:

```bash
task system:auto-update:status
```

## 6) Rollback

```bash
sudo rpm-ostree rollback
sudo systemctl reboot
```

## Workflow Summary

1. `task image:push` - build and push image
2. `task system:rebase` - rebase system (digest-pinned)
3. reboot
4. `backup-task restore:full` - restore home from snapshot (if needed)
5. reboot
6. `backup-task system:schedule` - re-enable backup timers

## Troubleshooting

**Build fails with `Packages not found`:**
- verify repo setup in `Dockerfile`
- package names can differ between Fedora versions

**Rebase fails with `Package 'rpmfusion-...-release' is already in the base`:**

```bash
sudo rpm-ostree uninstall rpmfusion-free-release rpmfusion-nonfree-release
sudo systemctl reboot
```

**Security note:** Never commit `cosign.key` into this repository. Rotate keys immediately on compromise.

