#!/usr/bin/env bash

set -Eeuo pipefail

: "${SHARD_NAME:?SHARD_NAME must be Master or Caves}"

dst_root="${DST_ROOT:-$HOME/dst}"
install_dir="${DST_INSTALL_DIR:-$dst_root/server_dst}"
cluster_name="${CLUSTER_NAME:-DSTCluster}"
cluster_dir="${KLEI_ROOT:-$HOME/.klei/DoNotStarveTogether}/$cluster_name"

server_binary="$install_dir/bin64/dontstarve_dedicated_server_nullrenderer_x64"
if [[ ! -x "$server_binary" ]]; then
    server_binary="$install_dir/bin/dontstarve_dedicated_server_nullrenderer"
fi
if [[ ! -x "$server_binary" ]]; then
    printf 'DST server binary not found in %s/bin64 or %s/bin\n' "$install_dir" "$install_dir" >&2
    exit 1
fi
if [[ ! -d "$cluster_dir" ]]; then
    printf 'Cluster configuration directory not found: %s\n' "$cluster_dir" >&2
    exit 1
fi

mkdir -p "$install_dir/mods"
cd "$(dirname "$server_binary")"
exec "$server_binary" -cluster "$cluster_name" -shard "$SHARD_NAME"
