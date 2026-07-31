#!/usr/bin/env bash

set -Eeuo pipefail

: "${SHARD_NAME:?SHARD_NAME must be set to Master or Caves}"

cluster_name="${CLUSTER_NAME:-DSTWhalesCluster}"
install_dir="${DST_INSTALL_DIR:-$HOME/server_dst}"
cluster_dir="$HOME/.klei/DoNotStarveTogether/$cluster_name"

if [[ "${UPDATE_SERVER:-true}" == "true" ]]; then
    # Update at startup so a newly released server build cannot remain stale.
    "$HOME/steamcmd.sh" \
        +@ShutdownOnFailedCommand 1 \
        +@NoPromptForPassword 1 \
        +force_install_dir "$install_dir" \
        +login anonymous \
        +app_update 343050 validate \
        +quit
fi

server_binary="$install_dir/bin64/dontstarve_dedicated_server_nullrenderer_x64"
if [[ ! -x "$server_binary" ]]; then
    server_binary="$install_dir/bin/dontstarve_dedicated_server_nullrenderer"
fi
if [[ ! -x "$server_binary" ]]; then
    printf 'DST server binary not found in %s/bin\n' "$install_dir" >&2
    exit 1
fi

mkdir -p "$cluster_dir"
cd "$(dirname "$server_binary")"
exec "$server_binary" -cluster "$cluster_name" -shard "$SHARD_NAME"
