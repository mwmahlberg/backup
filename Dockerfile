FROM quay.io/fedora-ostree-desktops/kinoite:43@sha256:d948e8a7290a7d1dbfcef588eaeb8f7ccb2333a7e63f877271fdc1c178cfec35

LABEL org.opencontainers.image.title="kinoite-workstation" \
  org.opencontainers.image.description="Custom Fedora Kinoite workstation image" \
  org.opencontainers.image.url="https://hub.docker.com/r/mwmahlberg/kinoite-workstation" \
  org.opencontainers.image.source="https://github.com/mwmahlberg/backup" \
  org.opencontainers.image.authors="Markus Mahlberg" \
  org.opencontainers.image.base.name="quay.io/fedora-ostree-desktops/kinoite:43@sha256:7675a82f2294e304d29ca553321f4eb02183fd4cbe6ad63a46179a8c4f6dd440"

# Avoid alloy %post useradd noise in rpm-ostree scriptlet sandbox by creating the account ahead of install.
RUN set -eu; \
  if ! getent group alloy >/dev/null 2>&1; then groupadd -r alloy; fi; \
  if ! getent passwd alloy >/dev/null 2>&1; then useradd -r -m -g alloy -d /var/lib/alloy -s /sbin/nologin -c "alloy user" alloy; fi

RUN set -eu; \
  arch="$(uname -m)"; \
  case "$arch" in \
  x86_64)  asset_arch=amd64 ;; \
  aarch64) asset_arch=arm64 ;; \
  *)       echo "Unsupported arch: $arch" >&2; exit 1 ;; \
  esac; \
  github_latest_tag() { \
  curl -fsSL "https://api.github.com/repos/$1/releases/latest" \
  | sed -n 's/^[[:space:]]*"tag_name":[[:space:]]*"\([^"]*\)".*/\1/p' \
  | head -n1; \
  }; \
  tmpdir="$(mktemp -d)"; \
  cosign_version="$(github_latest_tag sigstore/cosign)"; \
  curl -fsSL "https://github.com/sigstore/cosign/releases/download/${cosign_version}/cosign-linux-${asset_arch}" \
  -o "${tmpdir}/cosign"; \
  install -m 0755 "${tmpdir}/cosign" /usr/bin/cosign; \
  git_flow_version="$(github_latest_tag gittower/git-flow-next)"; \
  curl -fsSL "https://github.com/gittower/git-flow-next/releases/download/${git_flow_version}/git-flow-next-${git_flow_version}-linux-${asset_arch}.tar.gz" \
  | tar -xzf - -C "${tmpdir}"; \
  bin_path="$(find "${tmpdir}" -maxdepth 1 -type f -name 'git-flow*' | head -n1)"; \
  [ -n "${bin_path}" ] || { echo "git-flow binary not found in release archive" >&2; exit 1; }; \
  install -m 0755 "${bin_path}" /usr/bin/git-flow; \
  resticprofile_version="$(github_latest_tag creativeprojects/resticprofile)"; \
  curl -fsSL "https://github.com/creativeprojects/resticprofile/releases/download/${resticprofile_version}/resticprofile_${resticprofile_version#v}_linux_${asset_arch}.tar.gz" \
  | tar -xzf - -C "${tmpdir}" resticprofile; \
  install -m 0755 "${tmpdir}/resticprofile" /usr/bin/resticprofile; \
  rm -rf "${tmpdir}"; \
  cosign version; \
  git-flow version; \
  resticprofile version

COPY ostree/configs/etc/ /etc/
# Ship backup code in the image so restore/setup works without git clone.
COPY --parents \
  README.md README.de.md \
  CHANGELOG.md releaselog.md \
  Taskfile.yml .taskrc.yml .task/ \
  restic/ restore/ docs/ /usr/share/backup/

RUN chmod 0755 /usr/share/backup/restic/hooks/*.sh /usr/share/backup/restore/*.sh \
  && ln -sf /usr/share/backup/restore/backup-init.sh /usr/bin/backup-init \
  && ln -sf /usr/share/backup/restore/backup-task.sh /usr/bin/backup-task

# Harden the default container policy while keeping the known bootstrap sources explicit.
RUN jq '.default = [{"type":"reject"}] | .transports["docker-daemon"][""] = [{"type":"insecureAcceptAnything"}] | .transports.docker = {"docker.io/mwmahlberg/kinoite-workstation": [{"type":"insecureAcceptAnything"}]}' /etc/containers/policy.json > /tmp/policy.json \
  && install -m 0644 /tmp/policy.json /etc/containers/policy.json \
  && rm -f /tmp/policy.json

RUN rpm-ostree install \
  alloy \
  code \
  direnv \
  gh \
  git \
  go-task \
  gstreamer1-plugins-bad-freeworld \
  gstreamer1-plugins-ugly \
  intel-gpu-tools \
  intel-media-driver \
  iproute-tc \
  libavcodec-freeworld \
  libva-utils \
  powertop \
  restic \
  vim-enhanced \
  zram-generator \
  && ln -sf /usr/bin/go-task /usr/bin/task

# Commit the resulting ostree container layer.
RUN ostree container commit
