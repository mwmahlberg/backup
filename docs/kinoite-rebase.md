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
- `Containerfile.kinoite` enables RPM Fusion and the Microsoft VS Code repo before package installation.

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

## 4) Configure signature policy on target hosts

Install verification tools on each target host:

```bash
sudo rpm-ostree install cosign skopeo
sudo systemctl reboot
```

Copy your public verification key to the host, for example:

```bash
sudo install -D -m 0644 ./cosign.pub /etc/pki/containers/cosign.pub
```

Configure `/etc/containers/policy.json` to require sigstore signatures for your registry namespace:

```json
{
	"default": [{ "type": "reject" }],
	"transports": {
		"docker": {
			"ghcr.io/<your-user>": [
				{
					"type": "sigstoreSigned",
					"keyPath": "/etc/pki/containers/cosign.pub"
				}
			]
		}
	}
}
```

## 5) Rebase a host to the image

On a Kinoite host:

```bash
export IMAGE="ghcr.io/<your-user>/kinoite-workstation:latest"
export DIGEST="$(skopeo inspect --format '{{.Digest}}' "docker://$IMAGE")"
sudo rpm-ostree rebase "ostree-image-signed:docker://${IMAGE%@*}@${DIGEST}"
sudo systemctl reboot
```

After reboot, verify:

```bash
rpm-ostree status
```

## 6) Update hosts when image changes

After pushing a newer tag:

```bash
sudo rpm-ostree upgrade
sudo systemctl reboot
```

## 7) Rollback if needed

```bash
sudo rpm-ostree rollback
sudo systemctl reboot
```

## 8) Integrate with this backup repo

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

## Troubleshooting build errors

If build fails with `Packages not found`:

- verify you are using the repository's current `Containerfile.kinoite`
- ensure external repos were added before `rpm-ostree install` packages
- check package naming differences across Fedora versions (for example `intel-media-driver-free` vs older names)
- keep signing tools (`cosign`) on the build host; it is not required inside the Kinoite runtime image

If rebase fails with `Package 'rpmfusion-...-release' is already in the base`:

- remove layered release packages on the target before rebasing:

```bash
sudo rpm-ostree uninstall rpmfusion-free-release rpmfusion-nonfree-release
sudo systemctl reboot
```

- or use rebase-time overrides:

```bash
sudo rpm-ostree rebase --uninstall=rpmfusion-free-release --uninstall=rpmfusion-nonfree-release "ostree-unverified-registry:ghcr.io/<your-user>/kinoite-workstation@sha256:<digest>"
```