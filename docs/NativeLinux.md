# Native Linux Deployment

This path runs the DST server directly on Linux without Docker. Docker remains the recommended path because the image pins the base userspace and has been tested as a complete runtime. The native path below is a reference procedure and has not been verified on every listed distribution or kernel.

## Supported Target

Use a 64-bit `amd64` Linux host. Current DST includes a 64-bit server under `bin64/`, while SteamCMD still uses a 32-bit bootstrapper. ARM and Alpine/musl hosts are not recommended for this procedure.

You need:

- SteamCMD
- Bash, curl, tar and CA certificates
- 32-bit glibc, GCC runtime, libstdc++ and libcurl compatibility libraries
- A writable non-root user for the server
- UDP ports `10999` and `10998`

## Install Dependencies

### Debian or Ubuntu

```bash
sudo dpkg --add-architecture i386
sudo apt-get update
sudo apt-get install --no-install-recommends -y \
  bash ca-certificates curl tar \
  libc6:i386 lib32gcc-s1 lib32stdc++6 \
  libcurl3-gnutls libcurl3-gnutls:i386 \
  libcurl4 libcurl4:i386
```

Package names can vary between Ubuntu releases. On older releases, `lib32gcc1` and `lib32stdc++6` may replace the `*-s1` packages.

### Fedora, RHEL, Rocky or Alma Linux

```bash
sudo dnf install -y bash ca-certificates curl tar \
  glibc.i686 libgcc.i686 libstdc++.i686 libcurl.i686
```

RHEL-derived systems may require enabling the normal repositories or CodeReady Builder/PowerTools first. CentOS 7 is end-of-life and is not recommended.

### Arch Linux

Enable the `multilib` repository, then install:

```bash
sudo pacman -Syu --needed bash ca-certificates curl tar \
  lib32-glibc lib32-gcc-libs lib32-curl
```

### Other distributions

Install the equivalent 32-bit glibc and runtime libraries. Alpine uses musl rather than glibc and is outside this tested path; use Docker or a glibc-based distribution instead.

## Install SteamCMD and DST

Run this as the dedicated server user, not as root:

```bash
mkdir -p "$HOME/dst"
cd "$HOME/dst"
curl --fail --silent --show-error --location --retry 5 --retry-all-errors \
  https://media.steampowered.com/client/installer/steamcmd_linux.tar.gz \
  | tar -xzf -

./steamcmd.sh \
  +@ShutdownOnFailedCommand 1 \
  +@NoPromptForPassword 1 \
  +force_install_dir "$HOME/dst/server_dst" \
  +login anonymous \
  +app_update 343050 validate \
  +quit
```

The first download is several gigabytes. If SteamCMD reports an update timeout, retry the command or use the repository helper:

```bash
export DST_ROOT="$HOME/dst"
./scripts/native/update-server.sh
```

## Install Configuration

Create the Klei cluster directory and copy the tracked templates:

```bash
mkdir -p "$HOME/.klei/DoNotStarveTogether/DSTCluster"
cp -a DSTClusterConfig/. "$HOME/.klei/DoNotStarveTogether/DSTCluster/"
cp -a DSTClusterConfig/mods/. "$HOME/dst/server_dst/mods/" 2>/dev/null || true
```

Generate a Server Token at the [Klei account server page](https://accounts.klei.com/account/game/servers?game=DontStarveTogether) and replace the contents of:

```text
$HOME/.klei/DoNotStarveTogether/DSTCluster/cluster_token.txt
```

Keep only the token value. Change `cluster_name` and `cluster_password` in `cluster.ini`. Do not commit the token or save directory.

## Start the Shards

Update once, then start both shards without running two concurrent SteamCMD updates:

```bash
export DST_ROOT="$HOME/dst"
export CLUSTER_NAME=DSTCluster

./scripts/native/update-server.sh

SHARD_NAME=Master ./scripts/native/start-shard.sh
SHARD_NAME=Caves ./scripts/native/start-shard.sh
```

Run each shard in a separate `tmux`, `screen`, or systemd service. The Master must stay on the same cluster name and key as Caves. The script prefers `bin64/` and falls back to the legacy `bin/` executable.

## systemd Example

Install the repository somewhere stable, for example `/opt/dst-dedicated-server`, and create two units. Replace `dst` and paths with the actual service user and checkout path.

`/etc/systemd/system/dst-master.service`:

```ini
[Unit]
Description=DST Master shard
After=network-online.target
Wants=network-online.target

[Service]
User=dst
WorkingDirectory=/home/dst/dst/server_dst/bin64
Environment=DST_ROOT=/home/dst/dst
Environment=CLUSTER_NAME=DSTCluster
Environment=SHARD_NAME=Master
ExecStart=/opt/dst-dedicated-server/scripts/native/start-shard.sh
Restart=on-failure
RestartSec=10

[Install]
WantedBy=multi-user.target
```

Create `dst-caves.service` with the same content, but use `SHARD_NAME=Caves`, add `After=dst-master.service`, and use `Requires=dst-master.service` if Caves should stop with Master.

Before enabling the units, run the update manually. Then:

```bash
sudo systemctl daemon-reload
sudo systemctl enable --now dst-master.service dst-caves.service
systemctl status dst-master.service dst-caves.service
journalctl -u dst-master.service -u dst-caves.service -f
```

Set `UPDATE_SERVER=false` only affects the Docker entrypoint; the native procedure deliberately updates once before starting services.

## Firewall

Open UDP ports on the host and cloud security group:

```bash
sudo ufw allow 10999/udp
sudo ufw allow 10998/udp
```

For NPS or another relay, forward both UDP ports. TCP forwarding is only for the relay's control connection, not DST gameplay.

## Native Limitations

- Package names and library compatibility vary by distribution.
- ARM and Alpine are not covered by this procedure.
- SteamCMD and the game files are installed into the host filesystem, so upgrades and rollback need manual care.
- Host UID, permissions, systemd and firewall configuration are your responsibility.
- Klei/Steam outbound connectivity is still required; a DNS record or inbound relay cannot replace authentication.

For a reproducible runtime and the least host-specific troubleshooting, use the Docker deployment described in [README.md](../README.md).
