#!/bin/bash
# Send a desktop notification when rpm-ostreed has staged a new deployment.
# Intended to be called by rpm-ostree-notify.service after rpm-ostreed-automatic.service.
set -euo pipefail

# Find the first user with an active Wayland or X11 session.
user=""
while IFS= read -r line; do
    session_id=$(awk '{print $1}' <<< "$line")
    session_user=$(awk '{print $3}' <<< "$line")
    session_type=$(loginctl show-session "$session_id" -p Type --value 2>/dev/null || true)
    if [[ "$session_type" == "wayland" || "$session_type" == "x11" ]]; then
        user="$session_user"
        break
    fi
done < <(loginctl list-sessions --no-legend 2>/dev/null)

[[ -z "$user" ]] && exit 0

uid=$(id -u "$user")

# Check whether a staged (pending) deployment exists.
staged_version=$(rpm-ostree status --json 2>/dev/null | \
    python3 -c "
import sys, json
for d in json.load(sys.stdin).get('deployments', []):
    if d.get('staged'):
        print(d.get('version', 'unknown'))
        break
" 2>/dev/null || true)

[[ -z "$staged_version" ]] && exit 0

# Send the notification into the user's graphical session bus.
DBUS_SESSION_BUS_ADDRESS="unix:path=/run/user/${uid}/bus" \
    runuser -u "$user" -- \
    notify-send \
        --urgency=normal \
        --icon=system-software-update \
        --app-name="rpm-ostree" \
        "System update staged" \
        "Version ${staged_version} is ready and will be applied on next reboot."
