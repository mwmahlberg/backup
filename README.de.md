# backup

Custom Fedora Kinoite Workstation-Image und reproduzierbares Backup/Restore über `restic`/`resticprofile`.

## Schnellstart (5 Befehle)

Kein `git clone` nötig, da der notwendige Code im Image unter `/usr/share/backup` liegt.

```bash
backup-task setup:first-boot
backup-task restore:full
sudo systemctl reboot
backup-task system:schedule
backup-task doctor
```

## Was dieses Repository enthält

| Pfad                    | Zweck                                                                 |
| ----------------------- | --------------------------------------------------------------------- |
| `Dockerfile` | Custom Kinoite-Image (Pakete, Repos, Tools)                           |
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

### 1) Basisinstallation: Fedora Kinoite oder Silverblue

Fedora Kinoite oder Silverblue normal installieren. Nach dem ersten Boot weiter mit Schritt 2.

### 2) Rebase auf das eigene Image

Beim **allerersten** Rebase ist `task` noch nicht verfügbar; daher manuell:

```bash
sudo rpm-ostree rebase ostree-unverified-registry:docker.io/mwmahlberg/kinoite-workstation:43
sudo systemctl reboot
```

Nach dem Reboot ist das custom Image aktiv und `task` steht zur Verfügung.
Alle späteren Rebases (z. B. nach einem Push) laufen über:

```bash
task system:rebase
```

Details: [docs/kinoite-rebase.de.md](docs/kinoite-rebase.de.md)

### 3) Backup einrichten

Voraussetzung: Zugangsdaten liegen bereit (USB-Stick, Passwort-Manager o. ä.).

Kein Repository-Checkout nötig. Das Image liefert den Backup-Code unter `/usr/share/backup` mit,
und `backup-task` verwendet automatisch `Taskfile.yml` von dort.

One-command Setup:

```bash
RESTIC_REPOSITORY=s3:fra1.digitaloceanspaces.com/mwmbackups \
  AWS_ACCESS_KEY_ID=your-access-key \
  AWS_SECRET_ACCESS_KEY=your-secret-key \
  RESTIC_PASSWORD=your-restic-password \
  backup-task setup:first-boot
```

Alternative (nur Konfiguration anlegen, ohne Repository-Init und Schedule-Aktivierung):

```bash
backup-task restore:init
```

Details: [docs/backup.de.md](docs/backup.de.md)

### 4) Restore auf einem frischen System

Voraussetzung: Image ist bereits aktiv (Schritt 2), Zugangsdaten liegen bereit.
Restore am besten aus einer TTY (`Ctrl`+`Alt`+`F3`) oder vor dem ersten grafischen Login ausführen.

```bash
RESTIC_REPOSITORY=s3:fra1.digitaloceanspaces.com/mwmbackups \
  AWS_ACCESS_KEY_ID=your-access-key \
  AWS_SECRET_ACCESS_KEY=your-secret-key \
  RESTIC_PASSWORD=your-restic-password \
  backup-task restore:init

backup-task restore:full
```

Nach dem Restore:

```bash
sudo systemctl reboot
# nach Reboot:
backup-task system:schedule
```

Details: [docs/restore.de.md](docs/restore.de.md)

---

## Verfügbare Tasks

`backup-task help` zeigt den geführten Einstieg.

| Task                | Beschreibung                                    |
| ------------------- | ----------------------------------------------- |
| `help`              | Geführter Einstieg für Standard-Workflows       |
| `doctor`            | Voraussetzungen prüfen                          |
| `secrets:setup`     | Restic-Secret-Dateien anlegen                   |
| `secrets:check`     | Vorhandensein/Rechte von Restic-Secrets prüfen  |
| `setup:first-boot`  | One-command Ersteinrichtung                     |
| `restore:init`      | Restic-Konfiguration über Env-Variablen anlegen |
| `restore:full`      | Vollständiger Restore mit Next-Step-Hinweis     |
| `restore:bootstrap` | Workstation-Zustand manuell erneut anwenden     |
| `system:schedule`   | Backup-Zeitpläne nach Restore reaktivieren      |

---

## Detaillierte Dokumentation

- [docs/backup.de.md](docs/backup.de.md) — Backup-Workflow im Detail
- [docs/restore.de.md](docs/restore.de.md) — Restore-Workflow im Detail
- [docs/kinoite-rebase.de.md](docs/kinoite-rebase.de.md) — Image bauen, pushen und rebasen
