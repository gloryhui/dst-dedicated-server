# 管理服务器

以下命令在仓库根目录执行：

```bash
cd ~/dst-dedicated-server
```

## 启动

Docker 部署：

```bash
docker compose up -d --build
docker compose ps
docker compose logs -f
```

每个分片启动时会通过 SteamCMD 检查更新，临时失败会自动重试。需要跳过更新时，可以设置：

```bash
UPDATE_SERVER=false docker compose up -d
```

原生 Linux 部署见 [原生 Linux 文档](NativeLinux.md)。

## 查看日志

```bash
docker compose logs -f dst_master dst_caves
```

## 控制台命令

Master 分片拥有交互式终端：

```bash
docker attach dst_master
```

可以执行 `c_save()`、`c_shutdown()`、`c_regenerateworld()` 等命令。使用 `CTRL-p CTRL-q` 脱离而不停止容器；不要直接按 `CTRL-c`。

## 正常停止

优先在 Master 控制台执行：

```text
c_shutdown()
```

它会保存世界并通知 Caves 分片退出。

强制停止容器：

```bash
docker compose down
```

强制停止不保证最后的游戏进度已经保存。
