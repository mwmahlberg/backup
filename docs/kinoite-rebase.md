# kinoite rebase

Kinoite-focused image layering and `rpm-ostree rebase` workflow.

This approach is for system-level customization (`/usr`) and complements home backup/restore.
User data in `$HOME` should still be restored with restic.

## Goal

Create one custom Kinoite image layer, publish it, and apply it on target hosts with a single rebase command.

## 1) Start from the provided Containerfile

This repository includes `Containerfile.kinoite`.
Edit package list there to match your desired Kinoite layer.

Notes:

- Pin the Fedora release (`:42`, `:43`, etc.) to match your target lifecycle.
- Keep this image focused on system packages and system config only.

## 2) Build and push the image

Example (GHCR):

```bash
export IMAGE="ghcr.io/<your-user>/kinoite-workstation:latest"
podman build -t "$IMAGE" -f ./Containerfile.kinoite .
podman push "$IMAGE"
```

## 3) Sign the image (recommended)

Install signing/inspection tools on your build host:

```bash
sudo rpm-ostree install cosign skopeo
sudo systemctl reboot
```

Generate a key pair once (store private key securely):

```bash
cosign generate-key-pair
```

Sign pushed image:

```bash
cosign sign --key cosign.key "$IMAGE"
```

Verify signature before rebasing targets:

```bash
cosign verify --key cosign.pub "$IMAGE"
```

Optionally pin to digest for deterministic rollouts:

```bash
DIGEST="$(skopeo inspect --format '{{.Digest}}' "docker://$IMAGE")"
echo "$DIGEST"
```

## 4) Rebase a host to the image

On a Kinoite host:

```bash
export IMAGE="ghcr.io/<your-user>/kinoite-workstation:latest"
export DIGEST="$(skopeo inspect --format '{{.Digest}}' "docker://$IMAGE")"
sudo rpm-ostree rebase "ostree-unverified-registry:${IMAGE%@*}@${DIGEST}"
sudo systemctl reboot
```

After reboot, verify:

```bash
rpm-ostree status
```

`ostree-unverified-registry:` does not enforce signature checks by itself. Pair it with `cosign verify` in your rollout process.

## 5) Update hosts when image changes

After pushing a newer tag:

```bash
sudo rpm-ostree upgrade
sudo systemctl reboot
```

## 6) Rollback if needed

```bash
sudo rpm-ostree rollback
sudo systemctl reboot
```

## 7) Integrate with this backup repo

Recommended flow:

1. Rebase to your Kinoite image to restore system layer.
2. Restore home with `resticprofile ... restore ...`.
3. Let `[default.restore].run-after` apply state via `restore/bootstrap.sh`.
4. Optionally refresh backup repo checkout:

```bash
git -C ~/.local/share/backup pull --ff-only
```

## Security note

Treat image signing keys as production secrets. Store `cosign.key` outside this repository and rotate keys if compromise is suspected.