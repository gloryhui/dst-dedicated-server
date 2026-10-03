#!/usr/bin/env bash

set -Eeuo pipefail

: "${SHARD_NAME:?SHARD_NAME must be set to Master or Caves}"

cluster_name="${CLUSTER_NAME:-DSTWhalesCluster}"
install_dir="${DST_INSTALL_DIR:-$HOME/server_dst}"
cluster_dir="$HOME/.klei/DoNotStarveTogether/$cluster_name"

find_server_binary() {
    local binary
    for binary in \
        "$install_dir/bin64/dontstarve_dedicated_server_nullrenderer_x64" \
        "$install_dir/bin/dontstarve_dedicated_server_nullrenderer"; do
        if [[ -x "$binary" ]]; then
            printf '%s\n' "$binary"
            return 0
        fi
    done
    return 1
}

update_server() {
    local attempts="${STEAMCMD_UPDATE_ATTEMPTS:-3}"
    local attempt

    if ! [[ "$attempts" =~ ^[1-9][0-9]*$ ]]; then
        printf 'STEAMCMD_UPDATE_ATTEMPTS must be a positive integer\n' >&2
        return 2
    fi

    for ((attempt = 1; attempt <= attempts; attempt++)); do
        if "$HOME/steamcmd.sh" \
            +@ShutdownOnFailedCommand 1 \
            +@NoPromptForPassword 1 \
            +force_install_dir "$install_dir" \
            +login anonymous \
            +app_update 343050 validate \
            +quit; then
            return 0
        fi

        printf 'SteamCMD update failed (attempt %s/%s), retrying...\n' "$attempt" "$attempts" >&2
        sleep $((attempt * 5))
    done

    return 1
}

mkdir -p "$install_dir/mods"
if ! find_server_binary >/dev/null; then
    printf 'DST server is not installed; installing through SteamCMD...\n'
    update_server
elif [[ "${UPDATE_SERVER:-true}" == "true" ]]; then
    printf 'Checking DST server updates through SteamCMD...\n'
    update_server
fi

if ! server_binary="$(find_server_binary)"; then
    printf 'DST server binary not found in %s/bin64 or %s/bin\n' "$install_dir" "$install_dir" >&2
    exit 1
fi

mkdir -p "$cluster_dir"
cd "$(dirname "$server_binary")"
exec "$server_binary" -cluster "$cluster_name" -shard "$SHARD_NAME"
