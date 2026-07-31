# 原生 Linux 部署（不使用 Docker）

本路径直接在 Linux 主机上运行 DST 服务端，不使用 Docker。Docker 仍然是推荐方案，因为镜像固定了用户空间和运行依赖，并且完整运行环境已经验证过。下面的原生流程只是参考，未在列出的每个发行版、版本和内核上逐一实机验证。

SteamCMD 的命令顺序和下载地址参考 [Valve SteamCMD 文档](https://developer.valvesoftware.com/wiki/SteamCMD)，Token 流程参考 [Klei 官方 Server Token 页面](https://accounts.klei.com/account/game/servers?game=DontStarveTogether)。下面的依赖包名是各发行版的参考命令，不保证每个版本完全相同。

## 适用环境

建议使用 64 位 `amd64` Linux。当前 DST 的 64 位服务端位于 `bin64/`，但 SteamCMD 本身仍使用 32 位启动程序，因此必须安装 32 位 glibc 和运行库。ARM、Alpine/musl 主机不建议采用此流程。

需要准备：

- SteamCMD
- Bash、curl、tar、CA 证书
- 32 位 glibc、GCC runtime、libstdc++ 和 libcurl 兼容库
- 一个非 root 的专用服务器用户
- UDP 端口 `10999` 和 `10998`

## 安装依赖

### Debian 或 Ubuntu

```bash
sudo dpkg --add-architecture i386
sudo apt-get update
sudo apt-get install --no-install-recommends -y \
  bash ca-certificates curl tar \
  libc6:i386 lib32gcc-s1 lib32stdc++6 \
  libcurl3-gnutls libcurl3-gnutls:i386 \
  libcurl4 libcurl4:i386
```

旧版 Ubuntu 可能使用 `lib32gcc1` 和 `lib32stdc++6`，具体以发行版仓库为准。

### Fedora、RHEL、Rocky 或 Alma Linux

```bash
sudo dnf install -y bash ca-certificates curl tar \
  glibc.i686 libgcc.i686 libstdc++.i686 libcurl.i686
```

RHEL 系发行版可能需要先启用标准仓库或 CodeReady Builder/PowerTools。CentOS 7 已经停止维护，不推荐使用。

### Arch Linux

先启用 `multilib` 仓库，然后执行：

```bash
sudo pacman -Syu --needed bash ca-certificates curl tar \
  lib32-glibc lib32-gcc-libs lib32-curl
```

### 其他发行版

请安装等价的 32 位 glibc 和运行库。Alpine 使用 musl，不在本流程的验证范围内，建议改用 Docker 或基于 glibc 的发行版。

## 安装 SteamCMD 和 DST

使用专用服务器用户执行，不要使用 root：

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

首次下载约数 GB。如果 SteamCMD 更新超时，可以重试；也可以使用仓库脚本：

```bash
export DST_ROOT="$HOME/dst"
./scripts/native/update-server.sh
```

## 安装配置

创建 Klei 集群目录并复制模板：

```bash
mkdir -p "$HOME/.klei/DoNotStarveTogether/DSTCluster"
cp -a DSTClusterConfig/. "$HOME/.klei/DoNotStarveTogether/DSTCluster/"
cp -a DSTClusterConfig/mods/. "$HOME/dst/server_dst/mods/" 2>/dev/null || true
```

在 [Klei 账号服务器页面](https://accounts.klei.com/account/game/servers?game=DontStarveTogether)生成 Server Token，并替换：

```text
$HOME/.klei/DoNotStarveTogether/DSTCluster/cluster_token.txt
```

文件中只保留 Token 值。修改 `cluster.ini` 中的 `cluster_name` 和 `cluster_password`。不要提交 Token 或存档目录。

## 启动分片

先更新一次，再启动两个分片，避免两个分片同时运行 SteamCMD：

```bash
export DST_ROOT="$HOME/dst"
export CLUSTER_NAME=DSTCluster

./scripts/native/update-server.sh

SHARD_NAME=Master ./scripts/native/start-shard.sh
SHARD_NAME=Caves ./scripts/native/start-shard.sh
```

实际运行时请将两个分片分别放在 `tmux`、`screen` 或 systemd 服务中。Master 和 Caves 必须使用相同的集群名称和密钥。脚本优先使用 `bin64/`，找不到时回退到旧的 `bin/`。

## systemd

可以参考 [英文原生部署文档](NativeLinux.md) 中的 systemd 单元示例，创建 `dst-master.service` 和 `dst-caves.service`。Caves 服务应设置 `After=dst-master.service`，并根据需要设置 `Requires=dst-master.service`。

```bash
sudo systemctl daemon-reload
sudo systemctl enable --now dst-master.service dst-caves.service
systemctl status dst-master.service dst-caves.service
journalctl -u dst-master.service -u dst-caves.service -f
```

## 防火墙

在主机和云安全组放行 UDP：

```bash
sudo ufw allow 10999/udp
sudo ufw allow 10998/udp
```

NPS 或其他中转也必须转发两个 UDP 端口。TCP 只能用于穿透控制连接，不能用于 DST 游戏流量。

## 原生部署限制

- 不同发行版的包名和库兼容性不同。
- ARM、Alpine 不在此流程的验证范围内。
- SteamCMD 和游戏文件直接安装在主机上，升级和回滚需要自行管理。
- UID、权限、systemd 和防火墙需要自行维护。
- 仍然需要访问 Klei/Steam 的出站网络；DNS 或入站中转不能替代认证。

如果希望减少主机差异和排错成本，建议使用 [README 中的 Docker 部署](../README.zh_CN.md)。
