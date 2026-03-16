# kinoite rebase

Build, push, and apply a custom Kinoite image on target systems.

The custom image complements home backup with `restic`: it restores the system layer (`/usr`) while restic restores `$HOME`.

## 1) Adjust the Dockerfile

`Dockerfile` in the repository root contains all packages, repos, and tools.

Notes:
- match Fedora release (`:43`, etc.) to your target hosts
- keep the image focused on system packages and system config; user data belongs in restic
- RPM Fusion and the VS Code repo are enabled during build

## 2) Build, push, and sign image

```bash
task image:push
```

`image:push` rebuilds automatically when needed (source tracking on `Dockerfile`), logs in first,
pushes the image, and then signs the pushed digest with `cosign` keyless.

Local keyless signing can publish the identity returned by your IdP into public transparency
logs. Use CI signing as the default trust anchor unless you intentionally want to trust a
local signer as well.

Build only, without publishing:

```bash
task image:build
```

Manual equivalent (without task):

```bash
podman build -t docker.io/mwmahlberg/kinoite-workstation:43 -f Dockerfile .
podman push docker.io/mwmahlberg/kinoite-workstation:43
cosign sign --yes docker.io/mwmahlberg/kinoite-workstation:43@$(skopeo inspect --format '{{.Digest}}' docker://docker.io/mwmahlberg/kinoite-workstation:43)
```

Verify signature manually:

```bash
task image:verify
```

By default, `image:verify` trusts keyless signatures whose certificate identity matches
`https://github.com/mwmahlberg/backup/.github/workflows/build-push.yml@refs/heads/(main|develop)`
and whose issuer is GitHub Actions OIDC. Override `COSIGN_CERTIFICATE_IDENTITY_REGEXP` or
`COSIGN_CERTIFICATE_OIDC_ISSUER_REGEXP` when you intentionally want to trust a different signer.

> **Note:** The image now ships a stricter `/etc/containers/policy.json` with `default: reject`
> and explicit allowlists for `docker-daemon` and `docker.io/mwmahlberg/kinoite-workstation`.
> Host-side rebases still use `ostree-unverified-registry:` for now because the current
> `containers-policy.json` schema does not cleanly express GitHub Actions keyless workflow URIs.

## 3) First rebase (manual)

On the first rebase, the starting base can be Fedora Kinoite or Silverblue.
`task` may not be available yet, so use `rpm-ostree` directly:

```bash
sudo rpm-ostree rebase ostree-unverified-registry:docker://docker.io/mwmahlberg/kinoite-workstation:43
sudo systemctl reboot
```

After reboot, the custom image is active and `task` is available.

Check status:

```bash
rpm-ostree status
```

## 4) Follow-up rebases

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

## 5) Rollback

```bash
sudo rpm-ostree rollback
sudo systemctl reboot
```

## Workflow Summary

1. `task image:push` - build, push, and sign image
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

**Security note:** Keyless signing avoids storing a long-lived `cosign.key` in the repository or CI secrets.
