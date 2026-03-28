FROM quay.io/fedora-ostree-desktops/kinoite:43

LABEL org.opencontainers.image.title="kinoite-workstation" \
    org.opencontainers.image.description="Custom Fedora Kinoite workstation image" \
    org.opencontainers.image.url="https://hub.docker.com/r/mwmahlberg/kinoite-workstation" \
    org.opencontainers.image.source="https://github.com/mwmahlberg/backup" \
    org.opencontainers.image.authors="Markus Mahlberg" \
    org.opencontainers.image.base.name="quay.io/fedora-ostree-desktops/kinoite:43"

# Enable RPM Fusion and VS Code repository inside the image build.
RUN echo "rpmfusion-free-key-2020" >/dev/null && cat > /etc/yum.repos.d/rpmfusion-free.repo <<'EOF'
[rpmfusion-free]
name=RPM Fusion for Fedora $releasever - Free
metalink=https://mirrors.rpmfusion.org/metalink?repo=free-fedora-$releasever&arch=$basearch
enabled=1
gpgcheck=1
repo_gpgcheck=0
gpgkey=https://download1.rpmfusion.org/free/fedora/RPM-GPG-KEY-rpmfusion-free-fedora-2020
EOF

RUN echo "rpmfusion-nonfree-key-2020" >/dev/null && cat > /etc/yum.repos.d/rpmfusion-nonfree.repo <<'EOF'
[rpmfusion-nonfree]
name=RPM Fusion for Fedora $releasever - Nonfree
metalink=https://mirrors.rpmfusion.org/metalink?repo=nonfree-fedora-$releasever&arch=$basearch
enabled=1
gpgcheck=1
repo_gpgcheck=0
gpgkey=https://download1.rpmfusion.org/nonfree/fedora/RPM-GPG-KEY-rpmfusion-nonfree-fedora-2020
EOF

RUN cat > /etc/yum.repos.d/vscode.repo <<'EOF'
[code]
name=Visual Studio Code
baseurl=https://packages.microsoft.com/yumrepos/vscode
enabled=1
gpgcheck=1
repo_gpgcheck=0
gpgkey=https://packages.microsoft.com/keys/microsoft.asc
EOF

RUN curl -s -LO https://rpm.grafana.com/gpg.key \
    && rpm --import gpg.key \
    && rm gpg.key && \
    cat > /etc/yum.repos.d/grafana.repo <<'EOF'
[grafana]
name=grafana
baseurl=https://rpm.grafana.com
repo_gpgcheck=1
enabled=1
gpgcheck=1
gpgkey=https://rpm.grafana.com/gpg.key
sslverify=1
sslcacert=/etc/pki/tls/certs/ca-bundle.crt
EOF

# Avoid alloy %post useradd noise in rpm-ostree scriptlet sandbox by creating the account ahead of install.
RUN if ! getent group alloy >/dev/null 2>&1; then groupadd -r alloy; fi \
    && if ! getent passwd alloy >/dev/null 2>&1; then useradd -r -m -g alloy -d /var/lib/alloy -s /sbin/nologin -c "alloy user" alloy; fi

# Base workstation tools expected by this repository's backup and restore flow.
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
    jq \
    libavcodec-freeworld \
    libva-utils \
    powertop \
    restic \
    vim-enhanced \
    zram-generator

RUN ln -sf /usr/bin/go-task /usr/bin/task

# Install cosign (github.com/sigstore/cosign)
RUN set -eu; \
    arch="$(uname -m)"; \
    case "$arch" in \
    x86_64)  asset_arch=amd64 ;; \
    aarch64) asset_arch=arm64 ;; \
    *)       echo "Unsupported arch: $arch" >&2; exit 1 ;; \
    esac; \
    version="$(curl -fsSL https://api.github.com/repos/sigstore/cosign/releases/latest \
    | sed -n 's/^[[:space:]]*"tag_name":[[:space:]]*"\([^"]*\)".*/\1/p' | head -n1)"; \
    curl -fsSL "https://github.com/sigstore/cosign/releases/download/${version}/cosign-linux-${asset_arch}" \
    -o /usr/bin/cosign; \
    chmod 0755 /usr/bin/cosign; \
    cosign version

# Install git-flow-next (github.com/gittower/git-flow-next)
RUN set -eu; \
    arch="$(uname -m)"; \
    case "$arch" in \
    x86_64)  asset_arch=amd64 ;; \
    aarch64) asset_arch=arm64 ;; \
    *)       echo "Unsupported arch: $arch" >&2; exit 1 ;; \
    esac; \
    version="$(curl -fsSL https://api.github.com/repos/gittower/git-flow-next/releases/latest \
    | sed -n 's/^[[:space:]]*"tag_name":[[:space:]]*"\([^"]*\)".*/\1/p' | head -n1)"; \
    tmpdir="$(mktemp -d)"; \
    curl -fsSL "https://github.com/gittower/git-flow-next/releases/download/${version}/git-flow-next-${version}-linux-${asset_arch}.tar.gz" \
    | tar -xzf - -C "$tmpdir"; \
    bin_path="$(find "$tmpdir" -maxdepth 1 -type f -name 'git-flow*' | head -n1)"; \
    [ -n "$bin_path" ] || { echo "git-flow binary not found in release archive" >&2; exit 1; }; \
    install -m 0755 "$bin_path" /usr/bin/git-flow; \
    rm -rf "$tmpdir"; \
    git-flow version

# Install resticprofile (github.com/creativeprojects/resticprofile)
RUN set -eu; \
    arch="$(uname -m)"; \
    case "$arch" in \
    x86_64)  asset_arch=amd64 ;; \
    aarch64) asset_arch=arm64 ;; \
    *)       echo "Unsupported arch: $arch" >&2; exit 1 ;; \
    esac; \
    version="$(curl -fsSL https://api.github.com/repos/creativeprojects/resticprofile/releases/latest \
    | sed -n 's/^[[:space:]]*"tag_name":[[:space:]]*"\([^"]*\)".*/\1/p' | head -n1)"; \
    curl -fsSL "https://github.com/creativeprojects/resticprofile/releases/download/${version}/resticprofile_${version#v}_linux_${asset_arch}.tar.gz" \
    | tar -xzf - -C /tmp resticprofile; \
    install -m 0755 /tmp/resticprofile /usr/bin/resticprofile; \
    resticprofile version

# Ship backup code in the image so restore/setup works without git clone.
COPY Taskfile.yml /usr/share/backup/Taskfile.yml
COPY .taskrc.yml /usr/share/backup/.taskrc.yml
COPY .task/*.yml /usr/share/backup/.task/
COPY Dockerfile /usr/share/backup/Dockerfile
COPY restic/ /usr/share/backup/restic/
COPY restore/ /usr/share/backup/restore/
COPY docs/ /usr/share/backup/docs/
COPY README.md /usr/share/backup/README.md
COPY README.de.md /usr/share/backup/README.de.md
COPY CHANGELOG.md /usr/share/backup/CHANGELOG.md
COPY releaselog.md /usr/share/backup/releaselog.md
RUN chmod 0755 /usr/share/backup/restic/hooks/*.sh /usr/share/backup/restore/*.sh \
    && ln -sf /usr/share/backup/restore/backup-init.sh /usr/bin/backup-init \
    && ln -sf /usr/share/backup/restore/backup-task.sh /usr/bin/backup-task

# Harden the default container policy while keeping the known bootstrap sources explicit.
RUN jq '.default = [{"type":"reject"}] | .transports["docker-daemon"][""] = [{"type":"insecureAcceptAnything"}] | .transports.docker = {"docker.io/mwmahlberg/kinoite-workstation": [{"type":"insecureAcceptAnything"}]}' /etc/containers/policy.json > /tmp/policy.json \
    && install -m 0644 /tmp/policy.json /etc/containers/policy.json \
    && rm -f /tmp/policy.json

# Commit the resulting ostree container layer.
RUN ostree container commit
