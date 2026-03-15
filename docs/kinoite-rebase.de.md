# kinoite rebase

Kinoite-Image bauen, pushen und auf Zielsystemen anwenden.

Das Custom-Image ergänzt die Home-Sicherung mit `restic`: es stellt den System-Layer (`/usr`) wieder her, während Restic `$HOME` wiederherstellt.

## 1) Dockerfile anpassen

`Dockerfile` im Repository-Root enthält alle Pakete, Repos und Tools.

Hinweise:
- Fedora-Release (`:43` usw.) an den Zielhost anpassen.
- Das Image ist auf System-Pakete und -Konfiguration beschränkt; User-Daten gehören in Restic.
- RPM Fusion und der VS Code-Repo werden im Build aktiviert.

## 2) Image bauen und pushen

```bash
task image:push
```

`image:push` baut bei Bedarf automatisch neu (Quelldatei-Tracking auf `Dockerfile`) und loggt sich vorher ein.

Manuell (ohne Task):

```bash
podman build -t docker.io/mwmahlberg/kinoite-workstation:43 -f Dockerfile .
podman push docker.io/mwmahlberg/kinoite-workstation:43
```

## 3) Image signieren (geplant)

Einmalig ein Schlüsselpaar erzeugen (privaten Schlüssel sicher aufbewahren):

```bash
cosign generate-key-pair
```

Gepushtes Image signieren:

```bash
cosign sign --key cosign.key docker.io/mwmahlberg/kinoite-workstation:43
```

Signatur prüfen:

```bash
cosign verify --key cosign.pub docker.io/mwmahlberg/kinoite-workstation:43
```

> **Hinweis:** Sobald Signing aktiv ist, sollte der `system:rebase`-Task das TARGET-Präfix
> von `ostree-unverified-registry:` auf `ostree-image-signed:docker://` umstellen.

## 4) Erster Rebase (manuell)

Beim allerersten Rebase kann die Ausgangsbasis Fedora Kinoite oder Silverblue sein.
`task` ist noch nicht verfügbar; daher direkt mit `rpm-ostree`:

```bash
sudo rpm-ostree rebase ostree-unverified-registry:docker.io/mwmahlberg/kinoite-workstation:43
sudo systemctl reboot
```

Nach dem Reboot ist das Custom-Image aktiv und `task` steht zur Verfügung.

Status prüfen:

```bash
rpm-ostree status
```

## 5) Folge-Rebases

Nach jedem Push auf eine neue Version:

```bash
task system:rebase
```

`system:rebase` ermittelt den aktuellen Remote-Digest via `skopeo` und fragt vor dem Rebase nach Bestätigung.

## 6) Rollback

```bash
sudo rpm-ostree rollback
sudo systemctl reboot
```

## Gesamter Workflow (Zusammenfassung)

1. `task image:push` — Image bauen und pushen
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

**Sicherheitshinweis:** `cosign.key` nicht in dieses Repository einchecken. Schlüssel bei Kompromittierung sofort rotieren.

