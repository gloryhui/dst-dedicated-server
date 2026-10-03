#!/usr/bin/env bash
set -Eeuo pipefail

script_dir="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
image="${DST_IMAGE:-gloryhuis/dst-dedicated-server:latest}"

docker build --pull --platform linux/amd64 -t "$image" "$@" "$script_dir"
