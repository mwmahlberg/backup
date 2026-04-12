# backup

Detaillierter Backup-Workflow für dieses Repository.

## Überblick

Backups werden über `resticprofile` mit `restic/profiles.toml` verwaltet.
Das Standard-Profil:

- sichert das vollständige Home-Verzeichnis (`$HOME`)
- schließt Cache-, Build- und Container-Storage-Pfade aus
- exportiert Workstation-Zustandsdateien vor dem Backup
- pausiert laufende Podman-Container vor dem Backup und setzt sie danach fort
- wendet eine Aufbewahrungsrichtlinie an (`forget + prune`)

## Voraussetzungen

- Das Custom Kinoite-Image ist aktiv (`restic`, `resticprofile` und `task` bereits enthalten)
- Der mitgelieferte Backup-Code liegt unter `/usr/share/backup` (Aufruf via `backup-task`)
- `~/.config/restic/password` vorhanden
- `~/.config/restic/env` vorhanden mit S3-Zugangsdaten
- Optional, aber dringend empfohlen: ein dediziertes USB-Gerät für `backup-config/`
- Best Practice: ein verschlüsseltes USB-Gerät oder eine verschlüsselte Partition dafür verwenden

Beispiel `~/.config/restic/env`:

```bash
RESTIC_REPOSITORY=s3:fra1.digitaloceanspaces.com/mwmbackups
AWS_ACCESS_KEY_ID=your-access-key
AWS_SECRET_ACCESS_KEY=your-secret-key
```

Konfiguration automatisch anlegen lassen:

```bash
RESTIC_REPOSITORY=... AWS_ACCESS_KEY_ID=... AWS_SECRET_ACCESS_KEY=... RESTIC_PASSWORD=... \
  backup-task setup:first-boot
```

Empfohlen direkt nach der Einrichtung:

```bash
backup-task backup:save-settings
```

Dadurch werden `~/.config/restic/password` und `~/.config/restic/env` nach
`${USB_MOUNT}/backup-config/restic/` kopiert. Bei verschlüsselten Partitionen diese vorher
manuell entsperren und mounten, dann erst den Task ausführen.

## Profil-Verhalten

Profildatei: `restic/profiles.toml`

- `repository` zeigt auf S3-kompatiblen Speicher
- `password-file` und `env-file` werden aus `$HOME/.config/restic/` aufgelöst
- `run-before`:
  - pausiert Podman-Container
  - exportiert layered Pakete, Flatpaks und VS Code Extensions nach `~/.local/state/backup/`
- `run-finally` setzt Podman-Container fort
- Backup schließt `$HOME` ein (mit Ausnahmen)
- Maximale Kompression, Single-Filesystem

## Repository initialisieren (einmalig)

```bash
resticprofile -c ~/.local/share/backup/restic/profiles.toml init
```

## Manuelle Operationen

Backup ausführen:

```bash
resticprofile -c ~/.local/share/backup/restic/profiles.toml backup
```

Status des letzten Backups anzeigen:

```bash
backup-task backup:status
```

Verwaiste Repository-Locks entfernen:

```bash
backup-task backup:unlock
```

Konsistenzprüfung:

```bash
resticprofile -c ~/.local/share/backup/restic/profiles.toml check
```

Aufbewahrung anwenden:

```bash
resticprofile -c ~/.local/share/backup/restic/profiles.toml forget
```

Snapshots auflisten:

```bash
set -a; source ~/.config/restic/env; set +a
restic -r "$RESTIC_REPOSITORY" --password-file ~/.config/restic/password snapshots
```

## Zeitpläne (systemd user units)

Zeitpläne aktivieren (nach Ersteinrichtung oder nach Restore):

```bash
backup-task system:schedule
```

Zeitpläne direkt mit `resticprofile`:

```bash
resticprofile -c ~/.local/share/backup/restic/profiles.toml schedule --all --start --reload
systemctl --user list-timers '*resticprofile*'
```

Logs und Units:

```bash
journalctl --user -n 200 --no-pager | grep -i resticprofile
systemctl --user list-unit-files | grep -i resticprofile
```

Zeitpläne entfernen:

```bash
resticprofile -c ~/.local/share/backup/restic/profiles.toml unschedule --all
```

Timer ohne aktive Login-Session:

```bash
loginctl enable-linger "$USER"
```

## Hook-generierte Zustandsdateien

Diese Dateien werden vor jedem Backup erzeugt und im Snapshot gespeichert:

| Datei                                         | Inhalt                    |
| --------------------------------------------- | ------------------------- |
| `~/.local/state/backup/layered-packages.txt`  | layered rpm-ostree-Pakete |
| `~/.local/state/backup/flatpaks.txt`          | installierte Flatpak-Apps |
| `~/.local/state/backup/vscode-extensions.txt` | VS Code Extensions        |

## Troubleshooting

Kein Repository-Zugang / Auth-Fehler:
- `~/.config/restic/env` prüfen
- `~/.config/restic/password` prüfen
- Test: `restic snapshots` manuell ausführen

Backup hängt oder schlägt bei Containern fehl:
- Podman-Status: `podman ps -a`
- Verbose-Ausgabe: `resticprofile -v -c ~/.local/share/backup/restic/profiles.toml backup`

Fehlende Zustandsdateien:
- Hooks aus `restic/hooks/` manuell ausführen
