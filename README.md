# Don't Starve Together Dedicated Server

Docker deployment for a current Linux Don't Starve Together dedicated server.

The image installs Steam App `343050` with SteamCMD, prefers the current 64-bit server binary, and keeps the legacy 32-bit runtime as a fallback. The supported container platform is `linux/amd64`.

## Languages

| Language | Guide |
| --- | --- |
| English | This page |
| 简体中文 | [README.zh_CN.md](README.zh_CN.md) |
| 日本語 | [README.ja_JP.md](README.ja_JP.md) |
| 한국어 | [README.ko_KR.md](README.ko_KR.md) |

## Choose a Deployment

### Docker (recommended)

Requirements: Docker Engine or Docker Desktop with Compose v2, Git, and an `amd64` host. Docker Desktop can emulate `amd64` on ARM, but native amd64 is recommended for a dedicated server.

```bash
git clone https://github.com/mathielo/dst-dedicated-server.git
cd dst-dedicated-server
```

Generate a Server Token at the [Klei account server page](https://accounts.klei.com/account/game/servers?game=DontStarveTogether), then put only the token value in:

```text
DSTClusterConfig/cluster_token.txt
```

Start the Master and Caves shards:

```bash
docker compose up -d --build
docker compose ps
docker compose logs -f
```

The first build downloads the complete dedicated server and can take several minutes. Startup checks for updates through SteamCMD and retries transient update failures three times. Set `UPDATE_SERVER=false` on a service when an offline startup is required.

Stop the server with `c_shutdown()` from the Master console when possible so the world is saved. For a hard container stop:

```bash
docker compose down
```

### Native Linux (without Docker)

This path is for users who cannot or do not want to use Docker. It is a reference path and has not been verified on every listed distribution, kernel, or hardware platform. Docker is recommended for reproducible dependencies and easier upgrades.

The native host needs SteamCMD, Bash, curl, tar, CA certificates, and 32-bit glibc/GCC/libstdc++/libcurl compatibility libraries. The package names differ by distribution:

| Distribution family | Main packages |
| --- | --- |
| Debian/Ubuntu | `libc6:i386`, `lib32gcc-s1`, `lib32stdc++6`, `libcurl3-gnutls:i386`, `libcurl4:i386` |
| Fedora/RHEL/Rocky/Alma | `glibc.i686`, `libgcc.i686`, `libstdc++.i686`, `libcurl.i686` |
| Arch | `lib32-glibc`, `lib32-gcc-libs`, `lib32-curl` from `multilib` |

For Debian/Ubuntu:

```bash
sudo dpkg --add-architecture i386
sudo apt-get update
sudo apt-get install --no-install-recommends -y \
  bash ca-certificates curl tar libc6:i386 lib32gcc-s1 lib32stdc++6 \
  libcurl3-gnutls libcurl3-gnutls:i386 libcurl4 libcurl4:i386
```

Download SteamCMD from the current [Valve CDN](https://media.steampowered.com/client/installer/steamcmd_linux.tar.gz), install App `343050`, copy `DSTClusterConfig/` into `$HOME/.klei/DoNotStarveTogether/DSTCluster`, and run one shard per `tmux`, `screen`, or systemd service. The repository provides reusable helpers:

```bash
export DST_ROOT="$HOME/dst"
./scripts/native/update-server.sh
SHARD_NAME=Master ./scripts/native/start-shard.sh
SHARD_NAME=Caves ./scripts/native/start-shard.sh
```

The detailed native procedure, systemd units, distro notes, firewall setup and limitations are in [docs/NativeLinux.md](docs/NativeLinux.md). ARM, Alpine/musl, old CentOS and untested distro combinations should use Docker instead.

## Ports and Networking

The default Compose file publishes game traffic as UDP:

| Shard | Host port |
| --- | --- |
| Master | `10999/udp` |
| Caves | `10998/udp` |

Open both UDP ports in the host firewall, cloud security group, and any router or tunnel. Do not forward these game ports as TCP.

For NPS or another relay, create two UDP mappings, one for each port. The NPS client control connection may use TCP, but DST gameplay traffic remains UDP. A DNS record can provide a stable name, but DNS does not relay or improve connectivity by itself; use a Layer-4 UDP relay when players cannot reach the host directly.

Klei and Steam services are part of the server registration and authentication path. A relay can forward the game ports, but it cannot replace Klei authentication or guarantee that every region can reach Steam. Test the actual game path from each target region.

## Minimal Local Deployment

The working directory `deployment/` is intentionally Git-ignored. It contains a minimal Chinese Master+Caves setup with default world resources and no mods. It is local machine state, not a distributable repository artifact:

```bash
cd deployment
docker compose up -d --build
```

Use the tracked root Compose file for a fresh clone, or copy the ignored deployment directory separately.

## Configuration

| File | Purpose |
| --- | --- |
| `DSTClusterConfig/cluster.ini` | Name, password, player count, language and networking |
| `DSTClusterConfig/cluster_token.txt` | Private Klei Server Token; never commit it |
| `DSTClusterConfig/Master/server.ini` | Master port and shard identity |
| `DSTClusterConfig/Caves/server.ini` | Caves port and shard identity |
| `DSTClusterConfig/*/leveldataoverride.lua` | World generation settings |
| `DSTClusterConfig/mods/` | Mod setup and overrides |

The default world files use the current `version=4` format. Changing shard names, `master_ip`, `cluster_key`, or shard ports without updating both shards can break Master/Caves communication.

## Mods, Admins and Saves

- [Mod setup](DSTClusterConfig/mods/README.md)
- [Admins, bans and whitelist](docs/AdminBanWhitelist.md)
- [Server management](docs/ManagingTheServer.md)
- [Performance](docs/ServerPerformance.md)
- [Server Token](docs/ClusterToken.md)
- [Native Linux deployment](docs/NativeLinux.md)

Bind-mounted directories must be writable by the container user. On Linux, check ownership and permissions before using `chmod 777`; broad permissions are not a substitute for correct ownership.

## Publishing Images

The repository builds locally by default. For regional distribution, publish the same immutable tag to registries close to your players, for example GHCR, Docker Hub, Alibaba Cloud ACR, or a private Harbor registry:

```bash
docker buildx build --platform linux/amd64 \
  -t ghcr.io/OWNER/dst-dedicated-server:VERSION \
  --push .
```

Then set the Compose `image:` to the regional registry address. Do not publish the Klei token, save files, or `deployment/` contents inside an image. Prefer immutable version tags and keep a separate `latest` tag only as a convenience alias. A mirror reduces image download latency; it does not change DST server matchmaking, Klei authentication, or player-to-server UDP latency.

The Compose image can be overridden without editing YAML:

```bash
DST_IMAGE=registry.example.com/dst/dedicated-server:VERSION docker compose pull
DST_IMAGE=registry.example.com/dst/dedicated-server:VERSION docker compose up -d
```

## Troubleshooting

- Server is outdated: restart the services and inspect SteamCMD logs. The startup updater retries automatically.
- Server is not listed: verify the token, UDP `10998`/`10999`, cloud security group, NPS UDP mappings, and outbound access to Klei/Steam.
- Master/Caves do not connect: check the Docker network, `master_ip = dst_master`, `cluster_key`, and matching cluster name.
- Saves fail: inspect bind-mount ownership and look for `Failed to save file` in the logs.
- ARM host fails to start: use an amd64 host or enable Docker amd64 emulation.

## Official References

- [Valve SteamCMD documentation](https://developer.valvesoftware.com/wiki/SteamCMD)
- [Klei Server Token page](https://accounts.klei.com/account/game/servers?game=DontStarveTogether)
- [Klei dedicated server settings guide](https://forums.kleientertainment.com/topic/64552-dedicated-server-settings-guide/)
- [Klei dedicated server command-line guide](https://forums.kleientertainment.com/topic/64743-dedicated-server-command-line-options-guide/)

## License

MIT. See [LICENSE.md](LICENSE.md).
