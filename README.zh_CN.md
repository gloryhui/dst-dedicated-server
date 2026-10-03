# 饥荒：联机版专用服务器

使用 Docker 部署当前版本饥荒：联机版 Linux 专用服务器。

镜像只包含 SteamCMD、运行库和启动脚本；游戏文件在容器启动时下载到 Docker 持久卷。专用服务端对应 Steam App `343050`，优先运行当前 64 位服务端，同时保留旧 32 位运行时作为回退。支持的容器平台是 `linux/amd64`。

## 多语言

| 语言 | 文档 |
| --- | --- |
| English | [README.md](README.md) |
| 简体中文 | 当前页面 |
| 日本語 | [README.ja_JP.md](README.ja_JP.md) |
| 한국어 | [README.ko_KR.md](README.ko_KR.md) |

## 选择部署方式

### Docker（推荐）

要求：Docker Engine 或 Docker Desktop、Compose v2、Git，以及 `amd64` 主机。ARM 主机可以通过 Docker Desktop 模拟 `amd64`，但原生 amd64 更适合长期运行服务器。

```bash
git clone https://github.com/mathielo/dst-dedicated-server.git
cd dst-dedicated-server
```

在 [Klei 账号服务器页面](https://accounts.klei.com/account/game/servers?game=DontStarveTogether)生成 Server Token，只将 Token 值写入：

```text
DSTClusterConfig/cluster_token.txt
```

启动地上和洞穴分片：

```bash
docker compose up -d --build
docker compose ps
docker compose logs -f
```

首次启动容器时会下载完整专用服务器，可能需要几分钟。以后每次启动容器都会通过 SteamCMD 检查更新，已有文件会复用，临时失败最多尝试 3 次；更新失败则不启动分片。游戏运行期间不会定时检查更新。设置 `UPDATE_SERVER=false` 可跳过已安装服务端的更新；持久卷为空时仍需首次下载。

地上和洞穴各使用一个独立命名卷（`dst_master_server`、`dst_caves_server`），避免同时启动时更新同一套游戏文件。重启、重建容器或执行 `docker compose down` 会保留这些卷；`docker compose down -v` 会删除它们，下次启动需重新下载。配置、存档和 Mod 保持原有宿主机目录挂载。游戏更新不需要重建镜像。从不带游戏持久卷的旧镜像迁移时，首次启动会向新卷下载一套服务端。

尽量在 Master 控制台执行 `c_shutdown()` 后再停止，以确保世界保存。强制停止容器：

```bash
docker compose down
```

### 原生 Linux（不使用 Docker）

如果不能或不希望使用 Docker，可以直接在 Linux 主机运行服务端。这是参考流程，未在下列每个发行版、内核和硬件平台上逐一实机验证。Docker 更推荐，因为依赖可复现、升级和排错更简单。

原生主机需要 SteamCMD、Bash、curl、tar、CA 证书，以及 32 位 glibc/GCC/libstdc++/libcurl 兼容库。不同发行版的包名不同：

| 发行版家族 | 主要依赖 |
| --- | --- |
| Debian/Ubuntu | `libc6:i386`、`lib32gcc-s1`、`lib32stdc++6`、`libcurl3-gnutls:i386`、`libcurl4:i386` |
| Fedora/RHEL/Rocky/Alma | `glibc.i686`、`libgcc.i686`、`libstdc++.i686`、`libcurl.i686` |
| Arch | `multilib` 中的 `lib32-glibc`、`lib32-gcc-libs`、`lib32-curl` |

Debian/Ubuntu 安装依赖：

```bash
sudo dpkg --add-architecture i386
sudo apt-get update
sudo apt-get install --no-install-recommends -y \
  bash ca-certificates curl tar libc6:i386 lib32gcc-s1 lib32stdc++6 \
  libcurl3-gnutls libcurl3-gnutls:i386 libcurl4 libcurl4:i386
```

从当前 [Valve CDN](https://media.steampowered.com/client/installer/steamcmd_linux.tar.gz) 下载 SteamCMD，安装 App `343050`，将 `DSTClusterConfig/` 复制到 `$HOME/.klei/DoNotStarveTogether/DSTCluster`，然后使用 `tmux`、`screen` 或 systemd 分别运行两个分片。仓库提供了可复用脚本：

```bash
export DST_ROOT="$HOME/dst"
./scripts/native/update-server.sh
SHARD_NAME=Master ./scripts/native/start-shard.sh
SHARD_NAME=Caves ./scripts/native/start-shard.sh
```

完整的原生流程、systemd 单元、发行版差异、防火墙和限制见 [docs/NativeLinux.zh_CN.md](docs/NativeLinux.zh_CN.md)。ARM、Alpine/musl、旧 CentOS 和未验证的发行版组合建议使用 Docker。

## 端口与网络

默认 Compose 发布以下 UDP 端口：

| 分片 | 主机端口 |
| --- | --- |
| 地上 Master | `10999/udp` |
| 洞穴 Caves | `10998/udp` |

请在主机防火墙、云安全组、路由器或穿透服务中放行两个 UDP 端口，不要将游戏端口配置为 TCP。

使用 NPS 或其他中转时，需要建立两个 UDP 映射。NPS 客户端控制连接可以使用 TCP，但 DST 游戏流量必须保持 UDP。DNS 只能提供稳定域名，不能承担中转；玩家无法直连时，需要支持 UDP 的四层中转。

Klei 和 Steam 服务参与服务器注册与认证。中转只能转发游戏端口，不能替代 Klei 认证，也不能保证所有地区都能访问 Steam。应从目标地区实际测试游戏连接。

## 最小化本地部署

`deployment/` 已被 Git 忽略，其中包含一个简体中文、地上+洞穴、默认世界资源、无 Mod 的最小化部署。它是本机状态，不会进入仓库：

```bash
cd deployment
docker compose up -d --build
```

新克隆仓库时使用根目录 Compose；如需使用最小化部署，请另外复制被忽略的 `deployment/` 目录。

## 配置文件

| 文件 | 用途 |
| --- | --- |
| `DSTClusterConfig/cluster.ini` | 名称、密码、人数、语言和网络设置 |
| `DSTClusterConfig/cluster_token.txt` | 私有 Klei Token，禁止提交 |
| `DSTClusterConfig/Master/server.ini` | 地上端口和分片身份 |
| `DSTClusterConfig/Caves/server.ini` | 洞穴端口和分片身份 |
| `DSTClusterConfig/*/leveldataoverride.lua` | 世界生成设置 |
| `DSTClusterConfig/mods/` | Mod 安装与覆盖配置 |

默认世界配置使用当前 `version=4` 格式。不要随意修改分片名称、`master_ip`、`cluster_key` 或端口，否则可能破坏地上与洞穴之间的通信。

## Mod、管理员与存档

- [Mod 配置](DSTClusterConfig/mods/README.zh_CN.md)
- [管理员、封禁和白名单](docs/zh-CN/AdminBanWhitelist.md)
- [服务器管理](docs/zh-CN/ManagingTheServer.md)
- [性能优化](docs/zh-CN/ServerPerformance.md)
- [Server Token](docs/zh-CN/ClusterToken.md)
- [原生 Linux 部署](docs/NativeLinux.zh_CN.md)

绑定挂载目录必须允许容器用户写入。Linux 上优先检查所有者和权限，不要用 `chmod 777` 替代正确的目录归属。

## 镜像分发

项目默认本地构建。面向多国玩家时，可以将同一个不可变版本标签推送到玩家附近的 GHCR、Docker Hub、阿里云 ACR 或私有 Harbor：

`./build.sh` 固定构建 `linux/amd64`，检查基础镜像更新，默认标签为 `gloryhuis/dst-dedicated-server:latest`。可通过 `DST_IMAGE` 指定完整镜像标签；构建不会自动推送：

```bash
DST_IMAGE=gloryhuis/dst-dedicated-server:VERSION ./build.sh
docker push gloryhuis/dst-dedicated-server:VERSION
```

```bash
docker buildx build --platform linux/amd64 \
  -t ghcr.io/OWNER/dst-dedicated-server:VERSION \
  --push .
```

然后将 Compose 中的 `image:` 改为对应地区的镜像地址。不要把 Klei Token、存档或 `deployment/` 放进镜像；建议使用不可变版本标签，`latest` 只作为便利别名。镜像镜像只能降低下载镜像的时间，不能改变 DST 匹配、Klei 认证或玩家到服务器的 UDP 延迟。

也可以不修改 YAML，直接通过环境变量指定镜像：

```bash
DST_IMAGE=registry.example.com/dst/dedicated-server:VERSION docker compose pull
DST_IMAGE=registry.example.com/dst/dedicated-server:VERSION docker compose up -d
```

## 常见问题

- 服务器版本过旧：重启服务并查看 SteamCMD 日志，启动更新器会自动重试。
- 找不到服务器：检查 Token、UDP `10998`/`10999`、云安全组、NPS UDP 映射及访问 Klei/Steam 的出站网络。
- 地上和洞穴无法连接：检查 Docker 网络、`master_ip = dst_master`、`cluster_key` 和集群名称是否一致。
- 存档失败：检查绑定目录所有权，并在日志中搜索 `Failed to save file`。
- ARM 主机启动失败：使用 amd64 主机或启用 Docker amd64 模拟。

## 官方参考

- [Valve SteamCMD 文档](https://developer.valvesoftware.com/wiki/SteamCMD)
- [Klei Server Token 页面](https://accounts.klei.com/account/game/servers?game=DontStarveTogether)
- [Klei 专用服务器设置指南](https://forums.kleientertainment.com/topic/64552-dedicated-server-settings-guide/)
- [Klei 专用服务器命令行指南](https://forums.kleientertainment.com/topic/64743-dedicated-server-command-line-options-guide/)

## 许可证

MIT，见 [LICENSE.md](LICENSE.md)。
