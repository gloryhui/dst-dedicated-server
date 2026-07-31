#!/usr/bin/env bash

set -Eeuo pipefail

dst_root="${DST_ROOT:-$HOME/dst}"
install_dir="${DST_INSTALL_DIR:-$dst_root/server_dst}"
steamcmd="${STEAMCMD_PATH:-$dst_root/steamcmd.sh}"
app_id="${DST_APP_ID:-343050}"
attempts="${STEAMCMD_UPDATE_ATTEMPTS:-3}"

if [[ ! -x "$steamcmd" ]]; then
    printf 'SteamCMD not found or not executable: %s\n' "$steamcmd" >&2
    exit 1
fi
if ! [[ "$attempts" =~ ^[1-9][0-9]*$ ]]; then
    printf 'STEAMCMD_UPDATE_ATTEMPTS must be a positive integer\n' >&2
    exit 2
fi

mkdir -p "$install_dir/mods"
for ((attempt = 1; attempt <= attempts; attempt++)); do
    if "$steamcmd" \
        +@ShutdownOnFailedCommand 1 \
        +@NoPromptForPassword 1 \
        +force_install_dir "$install_dir" \
        +login anonymous \
        +app_update "$app_id" validate \
        +quit; then
        exit 0
    fi

    printf 'SteamCMD update failed (attempt %s/%s), retrying...\n' "$attempt" "$attempts" >&2
    sleep $((attempt * 5))
done

exit 1
