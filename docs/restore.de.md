# restore

Restore-Anleitung für ein frisch installiertes System mit dem Custom Kinoite-Image.

Das Image enthält bereits `restic`, `resticprofile` und `task`.
Zusätzlich wird der notwendige Backup-Code unter `/usr/share/backup` mitgeliefert, aufrufbar über `backup-task`.

## Überblick

Restore stellt das vollständige `$HOME` aus einem restic-Snapshot wieder her und wendet danach automatisch den gespeicherten Workstation-Zustand an:

- layered `rpm-ostree`-Pakete
- Flatpak-Apps
- VS Code Extensions

Die `resticprofile`-Restore-Konfiguration (`[default.restore]` in `restic/profiles.toml`) verwendet:
- `target = "/"` mit absolutem Pfad-Mapping
- `delete = true` – Dateien, die nicht im Snapshot enthalten sind, werden entfernt
- `exclude = ["$HOME/.config/restic"]` – lokale Zugangsdaten werden nie überschrieben
- `run-after = ".../restore/bootstrap.sh"` – Workstation-Zustand nach Restore automatisch wiederherstellen

## ⚠️ Voraussetzungen

**Ohne diese Informationen ist kein Restore möglich:**

| Was                                                  | Wo aufbewahren                                                   |
| ---------------------------------------------------- | ---------------------------------------------------------------- |
| `~/.config/restic/password`                          | USB-Stick, Passwort-Manager oder anderes sicheres Offline-Medium |
| S3-Zugangsdaten (Repository-URL, Access Key, Secret) | Dieselbe sichere Quelle                                          |

Diese Dateien sind aus dem Backup ausgeschlossen und werden beim Restore absichtlich nicht überschrieben.

## Sicherheitshinweis

Restore am besten aus einer TTY (`Ctrl`+`Alt`+`F3`) oder **vor dem ersten grafischen Login** ausführen,
damit laufende Desktop-Prozesse keine Dateien überschreiben, die gerade zurückgespielt werden.

## Schnellstart (Kurzcheckliste)

```bash
# 1. Konfiguration anlegen (Zugangsdaten aus USB-Stick / Passwort-Manager)
RESTIC_REPOSITORY=s3:fra1.digitaloceanspaces.com/mwmbackups \
  AWS_ACCESS_KEY_ID=your-access-key \
  AWS_SECRET_ACCESS_KEY=your-secret-key \
  RESTIC_PASSWORD=your-restic-password \
  backup-task restore:init

# 2. Restore ausführen
backup-task restore:full

# 3. Neu starten
sudo systemctl reboot

# 4. Nach Reboot: Backup-Zeitpläne aktivieren
backup-task system:schedule
```

## Schritt für Schritt

### 1) Konfiguration anlegen

```bash
RESTIC_REPOSITORY=s3:fra1.digitaloceanspaces.com/mwmbackups \
  AWS_ACCESS_KEY_ID=your-access-key \
  AWS_SECRET_ACCESS_KEY=your-secret-key \
  RESTIC_PASSWORD=your-restic-password \
  backup-task restore:init
```

`restore:init` legt an:
- `~/.config/restic/password` (chmod 600)
- `~/.config/restic/env` (chmod 600)
- `~/.config/resticprofile/profiles.toml` (Symlink auf `restic/profiles.toml`)

### 2) Snapshots prüfen (optional)

```bash
set -a; source ~/.config/restic/env; set +a
restic \
  -r "$RESTIC_REPOSITORY" \
  --password-file ~/.config/restic/password \
  snapshots
```

### 3) Restore ausführen

Neuesten Snapshot:

```bash
backup-task restore:run
```

Bestimmte Snapshot-ID (manuell via `resticprofile`):

```bash
resticprofile -c ~/.local/share/backup/restic/profiles.toml restore 70e69674
```

`restore/bootstrap.sh` wird automatisch nach erfolgreichem Restore ausgeführt und stellt layered Pakete, Flatpaks und VS Code Extensions wieder her.

### 4) Neu starten und prüfen

```bash
sudo systemctl reboot
```

Nach Reboot: Shell-Konfiguration, Dotfiles, Projektverzeichnisse und Anwendungen prüfen.

### 5) Backup-Zeitpläne reaktivieren

```bash
backup-task system:schedule
```

Optional, damit Timer auch ohne aktive Login-Session laufen:

```bash
loginctl enable-linger "$USER"
```

## Workstation-Zustand manuell erneut anwenden

Falls `bootstrap.sh` erneut ausgeführt werden soll (z. B. nach partiell fehlgeschlagenen Paket-Installationen):

```bash
backup-task restore:bootstrap
```

## Zustandsdateien

Diese Dateien werden beim Backup durch die Hooks in `restic/hooks/` erzeugt und im Snapshot gespeichert:

| Datei                                         | Inhalt                    |
| --------------------------------------------- | ------------------------- |
| `~/.local/state/backup/layered-packages.txt`  | layered rpm-ostree-Pakete |
| `~/.local/state/backup/flatpaks.txt`          | installierte Flatpak-Apps |
| `~/.local/state/backup/vscode-extensions.txt` | VS Code Extensions        |

