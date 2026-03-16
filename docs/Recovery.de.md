# recovery

Vollständiger Recovery-Pfad von einem frisch installierten Fedora Silverblue bis zu einer vollständig wiederhergestellten Workstation.

Annahmen:
- Fedora Silverblue ist frisch installiert
- Netzwerk ist bereits konfiguriert
- das Custom-Image liegt unter `docker.io/mwmahlberg/kinoite-workstation:43`
- die Restore-Zugangsdaten liegen entweder auf einem sicheren USB-Gerät oder in einer anderen sicheren Quelle vor

## Was du vorab brauchst

- Zugriff auf die Backup-Zugangsdaten:
  - `~/.config/restic/password`
  - `~/.config/restic/env`
- oder die entsprechenden Variablen:
  - `RESTIC_REPOSITORY`
  - `AWS_ACCESS_KEY_ID`
  - `AWS_SECRET_ACCESS_KEY`
  - `RESTIC_PASSWORD`
- empfohlen: ein dediziertes verschlüsseltes USB-Gerät oder eine verschlüsselte Partition mit:

```bash
backup-task backup:save-settings
```

## 1) Silverblue auf das Custom-Image rebases

Auf einem frischen System ist `task` noch nicht verfügbar. Der erste Rebase erfolgt deshalb manuell:

```bash
sudo rpm-ostree rebase ostree-unverified-registry:docker://docker.io/mwmahlberg/kinoite-workstation:43
sudo systemctl reboot
```

Nach dem Reboot ist das Custom-Image aktiv und `backup-task` verfügbar.

## 2) Vor dem Restore auf eine TTY wechseln

Den destruktiven Restore am besten:
- aus einer TTY, z. B. mit `Ctrl`+`Alt`+`F3`
- oder vor dem ersten grafischen Login

So vermeidest du, dass laufende Desktop-Prozesse in den Restore hineinfunken.

## 3) Optional: gespeicherte Einstellungen vom USB-Gerät zurückholen

Wenn du die restore-kritischen Dateien vorher auf ein USB-Gerät gesichert hast, hole sie zuerst zurück:

```bash
backup-task backup:restore-settings
```

Das ist besonders praktisch, wenn das USB-Gerät bereits diese Dateien enthält:
- `backup-config/restic/password`
- `backup-config/restic/env`

Falls die gewählte Partition mit LUKS verschlüsselt ist, musst du sie vorher manuell entsperren und mounten.

## 4) Alternative: Restore-Konfiguration aus Umgebungsvariablen anlegen

Wenn du `backup:restore-settings` nicht verwendest, kannst du die lokale Restore-Konfiguration direkt erzeugen:

```bash
RESTIC_REPOSITORY=s3:fra1.digitaloceanspaces.com/mwmbackups \
  AWS_ACCESS_KEY_ID=your-access-key \
  AWS_SECRET_ACCESS_KEY=your-secret-key \
  RESTIC_PASSWORD=your-restic-password \
  backup-task restore:init
```

`restore:init` legt an:
- `~/.config/restic/password`
- `~/.config/restic/env`
- `~/.config/resticprofile/profiles.toml`

## 5) Restore-Voraussetzungen prüfen

```bash
backup-task restore:check
```

Geprüft werden:
- benötigte Binaries sind vorhanden
- das mitgelieferte restic-Profil existiert
- lokale restic-Zugangsdaten sind vorhanden
- das Repository ist erreichbar
- mindestens ein Snapshot ist verfügbar

## 6) Optional: Snapshots prüfen

```bash
backup-task restore:list-snapshots
```

Um statt des neuesten Snapshots gezielt einen bestimmten Snapshot zurückzuspielen:

```bash
backup-task restore:snapshot SNAPSHOT=<snapshot-id>
```

## 7) Vollständigen Restore ausführen

```bash
backup-task restore:full
```

Dadurch wird `$HOME` aus dem neuesten Snapshot wiederhergestellt und anschließend automatisch `restore/bootstrap.sh` ausgeführt.

Der Bootstrap-Schritt stellt den gespeicherten Workstation-Zustand wieder her, darunter:
- layered `rpm-ostree`-Pakete
- Flatpak-Apps
- VS Code Extensions

## 8) In das wiederhergestellte System neu starten

```bash
sudo systemctl reboot
```

## 9) Backup-Zeitpläne wieder aktivieren

Nach dem Reboot:

```bash
backup-task system:schedule
```

Optional, wenn User-Timer auch ohne aktive Login-Session laufen sollen:

```bash
loginctl enable-linger "$USER"
```

## 10) Abschlussprüfung

Prüfe, ob das System wieder vollständig nutzbar ist:
- Shell-Konfiguration und Dotfiles
- Projektverzeichnisse
- Flatpaks und Desktop-Apps
- VS Code und Extensions
- Backup-Timer

Den Timer-Status kannst du so prüfen:

```bash
systemctl --user list-timers '*resticprofile*'
```

## Kurzfassung

```bash
sudo rpm-ostree rebase ostree-unverified-registry:docker://docker.io/mwmahlberg/kinoite-workstation:43
sudo systemctl reboot

# vor dem Fortfahren auf eine TTY wechseln

# optional:
backup-task backup:restore-settings

# falls nötig statt des vorherigen Schritts:
RESTIC_REPOSITORY=s3:fra1.digitaloceanspaces.com/mwmbackups \
  AWS_ACCESS_KEY_ID=your-access-key \
  AWS_SECRET_ACCESS_KEY=your-secret-key \
  RESTIC_PASSWORD=your-restic-password \
  backup-task restore:init

backup-task restore:check
backup-task restore:list-snapshots
backup-task restore:full
sudo systemctl reboot
backup-task system:schedule
```
