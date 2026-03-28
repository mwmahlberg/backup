# kinoite rebase

Kinoite-Image bauen, pushen und auf Zielsystemen anwenden.

Das Custom-Image ergänzt die Home-Sicherung mit `restic`: es stellt den System-Layer (`/usr`) wieder her, während Restic `$HOME` wiederherstellt.

## 1) Dockerfile anpassen

`Dockerfile` im Repository-Root enthält alle Pakete, Repos und Tools.

Hinweise:
- Fedora-Release (`:43` usw.) an den Zielhost anpassen.
- Das Image ist auf System-Pakete und -Konfiguration beschränkt; User-Daten gehören in Restic.
- RPM Fusion und der VS Code-Repo werden im Build aktiviert.

## 2) Image bauen, pushen und signieren

```bash
task image:push
```

`image:push` baut bei Bedarf automatisch neu (Quelldatei-Tracking auf `Dockerfile`), loggt sich vorher ein,
pusht das Image und signiert danach den gepushten Digest per `cosign` keyless.

Lokales keyless Signing kann die vom IdP gelieferte Identitaet in oeffentliche Transparenz-Logs
schreiben. Fuer den Standard-Trust sollte deshalb CI-Signing die erste Wahl bleiben, ausser du
willst lokale Signierer bewusst mit vertrauen.

Nur lokal bauen, ohne Publish:

```bash
task image:build
```

Manuell (ohne Task):

```bash
podman build -t docker.io/mwmahlberg/kinoite-workstation:43 -f Dockerfile .
podman push docker.io/mwmahlberg/kinoite-workstation:43
cosign sign --yes docker.io/mwmahlberg/kinoite-workstation:43@$(skopeo inspect --format '{{.Digest}}' docker://docker.io/mwmahlberg/kinoite-workstation:43)
```

Signatur manuell prüfen:

```bash
task image:verify
```

Standardmaessig vertraut `image:verify` keyless Signaturen, deren Zertifikats-Identity auf
`https://github.com/mwmahlberg/backup/.github/workflows/publish-release.yml@refs/tags/v.+`
passt und deren Issuer GitHub Actions OIDC ist. Mit `COSIGN_CERTIFICATE_IDENTITY_REGEXP` oder
`COSIGN_CERTIFICATE_OIDC_ISSUER_REGEXP` kannst du das fuer andere Signierer bewusst anpassen.

> **Hinweis:** Das Image liefert jetzt eine strengere `/etc/containers/policy.json` mit
> `default: reject` und expliziten Allowlists für `docker-daemon` sowie
> `docker.io/mwmahlberg/kinoite-workstation` mit. Host-Rebases bleiben vorerst bei
> `ostree-unverified-registry:`, weil das aktuelle `containers-policy.json`-Schema die
> GitHub-Actions-Keyless-Workflow-URI noch nicht sauber ausdrücken kann.

## 3) Erster Rebase (manuell)

Beim allerersten Rebase kann die Ausgangsbasis Fedora Kinoite oder Silverblue sein.
`task` ist noch nicht verfügbar; daher direkt mit `rpm-ostree`:

```bash
sudo rpm-ostree rebase ostree-unverified-registry:docker://docker.io/mwmahlberg/kinoite-workstation:43
sudo systemctl reboot
```

Nach dem Reboot ist das Custom-Image aktiv und `task` steht zur Verfügung.

Status prüfen:

```bash
rpm-ostree status
```

## 4) Folge-Rebases

Nach jedem Push auf eine neue Version:

```bash
task system:rebase
```

`system:rebase` ermittelt den aktuellen Remote-Digest via `skopeo` und fragt vor dem Rebase nach Bestätigung.

## 5) Rollback

```bash
sudo rpm-ostree rollback
sudo systemctl reboot
```

## Gesamter Workflow (Zusammenfassung)

1. `task image:push` — Image bauen, pushen und signieren
2. `task system:rebase` — System rebasen (mit Digest-Pinning)
3. Neu starten
4. `backup-task restore:full` — Home aus Snapshot wiederherstellen (falls nötig)
5. Neu starten
6. `backup-task system:schedule` — Backup-Timer reaktivieren

## Troubleshooting

**Build schlägt fehl mit `Packages not found`:**
- Repo-Definitionen in `Dockerfile` prüfen
- Paketnamen können je Fedora-Version abweichen

**Rebase schlägt fehl mit `Package 'rpmfusion-...-release' is already in the base`:**

```bash
sudo rpm-ostree uninstall rpmfusion-free-release rpmfusion-nonfree-release
sudo systemctl reboot
```

**Sicherheitshinweis:** Keyless-Signing vermeidet einen langlebigen `cosign.key` im Repository oder in CI-Secrets.
