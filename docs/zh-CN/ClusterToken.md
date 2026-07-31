# 生成 Cluster Token

DST 专用服务器需要 Klei Server Token 才能在线启动。

Token 必须由你的 Steam/Klei 账号生成。生成 Token 的账号会自动获得该服务器的管理员权限。

## 网页生成

打开 [Klei 服务器 Token 页面](https://accounts.klei.com/account/game/servers?game=DontStarveTogether)，登录后生成 Server Token。

将 Token 的值写入：

```text
DSTClusterConfig/cluster_token.txt
```

文件中只保留 Token 本身，不要包含字段名、引号、空格或其他配置内容。

## 游戏内控制台生成

进入游戏并登录后，按 `~` 打开控制台，执行：

```lua
TheNet:GenerateClusterToken()
```

生成的文件通常位于：

- Linux/macOS：`~/.klei/DoNotStarveTogether/cluster_token.txt`
- Windows：`文档/Klei/DoNotStarveTogether/cluster_token.txt`

复制文件中的 Token 值到服务器的 `cluster_token.txt`。

## 安全注意

Token 是敏感凭据，不要提交到 Git、镜像或公开日志。Token 失效后需要在 Klei 页面重新生成，并重启服务器。
