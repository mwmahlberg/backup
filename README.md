# backup

Custom Fedora Kinoite Workstation-Image und reproduzierbares Backup/Restore über `restic`/`resticprofile`.

## Was dieses Repository enthält

| Pfad                    | Zweck                                                                 |
| ----------------------- | --------------------------------------------------------------------- |
| `Containerfile.kinoite` | Custom Kinoite-Image (Pakete, Repos, Tools)                           |
| `Taskfile.yml`          | Aufgabenautomatisierung (`task`) für Build, Push, Rebase, Restore     |
| `restic/profiles.toml`  | resticprofile-Konfiguration (Backup, Check, Forget, Restore)          |
| `restic/hooks/`         | Hooks: exportiert Pakete, Flatpaks, VS Code Extensions vor dem Backup |
| `restore/bootstrap.sh`  | Wendet gespeicherten Workstation-Zustand nach Restore an              |
| `docs/`                 | Detaillierte Anleitungen                                              |

Generierte Zustandsdateien (`~/.local/state/backup/`) sind bewusst nicht in Git – sie werden beim Backup erstellt und mit gesichert.

---

## ⚠️ Was auf einem USB-Stick (oder sicher offline) liegen muss

Diese Dateien sind **nicht im Backup enthalten** (`~/.config/restic` ist explizit ausgeschlossen).
Ohne sie ist kein Restore möglich, falls das Gerät verloren geht.

| Datei                       | Inhalt                                                                              |
| --------------------------- | ----------------------------------------------------------------------------------- |
| `~/.config/restic/password` | Passwort für das restic-Repository                                                  |
| `~/.config/restic/env`      | S3-Zugangsdaten (`RESTIC_REPOSITORY`, `AWS_ACCESS_KEY_ID`, `AWS_SECRET_ACCESS_KEY`) |

Beispiel-Inhalt `~/.config/restic/env`:

```bash
RESTIC_REPOSITORY=s3:fra1.digitaloceanspaces.com/mwmbackups
AWS_ACCESS_KEY_ID=your-access-key
AWS_SECRET_ACCESS_KEY=your-secret-key
```

---

## Gesamter Workflow

### 1) Basisinstallation: Fedora Kinoite

Fedora Kinoite normal installieren. Nach dem ersten Boot weiter mit Schritt 2.

### 2) Rebase auf das eigene Image

Beim **allerersten** Rebase ist `task` noch nicht verfügbar; daher manuell:

```bash
sudo rpm-ostree rebase ostree-unverified-registry:docker.io/mwmahlberg/kinoite-workstation:latest
sudo systemctl reboot
```

Nach dem Reboot ist das custom Image aktiv und `task` steht zur Verfügung.
Alle späteren Rebases (z. B. nach einem Push) laufen über:

```bash
task system:rebase
```

Details: [docs/kinoite-rebase.md](docs/kinoite-rebase.md)

### 3) Backup einrichten

Voraussetzung: Zugangsdaten liegen bereit (USB-Stick, Passwort-Manager o. ä.).

Dieses Repository klonen:

```bash
git clone https://github.com/mwmahlberg/backup.git ~/.local/share/backup
cd ~/.local/share/backup
```

Konfiguration anlegen (Zugangsdaten als Umgebungsvariablen übergeben):

```bash
RESTIC_REPOSITORY=s3:fra1.digitaloceanspaces.com/mwmbackups \
  AWS_ACCESS_KEY_ID=your-access-key \
  AWS_SECRET_ACCESS_KEY=your-secret-key \
  RESTIC_PASSWORD=your-restic-password \
  task restore:init
```

Repository initialisieren (einmalig, nur bei Ersteinrichtung):

```bash
resticprofile -c ~/.local/share/backup/restic/profiles.toml init
```

Backup-Zeitpläne (systemd user units) aktivieren:

```bash
task restore:schedule
```

Details: [docs/backup.md](docs/backup.md)

### 4) Restore auf einem frischen System

Voraussetzung: Image ist bereits aktiv (Schritt 2), Zugangsdaten liegen bereit.
Restore am besten aus einer TTY (`Ctrl`+`Alt`+`F3`) oder vor dem ersten grafischen Login ausführen.

```bash
git clone https://github.com/mwmahlberg/backup.git ~/.local/share/backup
cd ~/.local/share/backup

RESTIC_REPOSITORY=s3:fra1.digitaloceanspaces.com/mwmbackups \
  AWS_ACCESS_KEY_ID=your-access-key \
  AWS_SECRET_ACCESS_KEY=your-secret-key \
  RESTIC_PASSWORD=your-restic-password \
  task restore:init

task restore:run
```

Nach dem Restore:

```bash
sudo systemctl reboot
# nach Reboot:
task restore:schedule
```

Details: [docs/restore.md](docs/restore.md)

---

## Verfügbare Tasks

```
task --list
```

| Task                | Beschreibung                                              |
| ------------------- | --------------------------------------------------------- |
| `image:build`       | Kinoite-Image lokal bauen                                 |
| `image:push`        | Image in die Registry pushen (baut bei Bedarf, loggt ein) |
| `image:digest`      | Remote-Digest des Images anzeigen                         |
| `system:rebase`     | System auf aktuellen Image-Digest rebasen                 |
| `registry:login`    | In Container-Registry einloggen                           |
| `registry:logout`   | Aus Container-Registry ausloggen                          |
| `ostree:login`      | ostree-Auth (`/etc/ostree/auth.json`) konfigurieren       |
| `ostree:logout`     | Registry aus ostree-Auth entfernen                        |
| `restore:init`      | restic-Konfiguration auf frischem System anlegen          |
| `restore:run`       | HOME aus letztem Snapshot wiederherstellen                |
| `restore:bootstrap` | Workstation-Zustand manuell erneut anwenden               |
| `restore:schedule`  | Backup-Zeitpläne nach Restore reaktivieren                |

---

## Detaillierte Dokumentation

- [docs/backup.md](docs/backup.md) — Backup-Workflow im Detail
- [docs/restore.md](docs/restore.md) — Restore-Workflow im Detail
- [docs/kinoite-rebase.md](docs/kinoite-rebase.md) — Image bauen, pushen und rebasen
