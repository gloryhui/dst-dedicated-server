# 管理员、封禁与白名单

在以下文件中每行写入一个玩家的唯一标识：

```text
DSTClusterConfig/
  adminlist.txt
  blocklist.txt
  whitelist.txt
```

玩家标识通常以 `KU_` 开头，例如：

```text
KU_A1b2C3d4
KU_aAaA11bB
```

## 管理员

将玩家标识写入 `adminlist.txt`。管理员可以踢人、封禁玩家并执行服务器 Lua 命令，因此只授予可信用户。

## 白名单

将玩家标识写入 `whitelist.txt`。白名单玩家始终可以进入服务器，并会占用服务器的公开名额。

## 封禁

将玩家标识写入 `blocklist.txt`。也可以在游戏界面执行踢出/封禁，服务器会自动更新该文件。

## 从日志获取标识

玩家加入时查看 Master 日志：

```text
Client authenticated: (KU_aBCd1234) PlayerName
```

其中 `KU_aBCd1234` 就是玩家标识。可用以下命令查看：

```bash
docker compose logs -f dst_master
```

修改列表文件后，通常需要让玩家重新连接；必要时重启分片。不要把真实玩家标识和日志公开发布。
