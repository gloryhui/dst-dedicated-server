# Mod 管理

## 安装 Mod

查看 `dedicated_server_mods_setup.lua`，按注释加入需要下载的 Workshop Mod。

## 启用和配置 Mod

查看 `modoverrides.lua`。Mod 下载后不代表已启用，必须为对应 Mod 设置 `enabled=true`：

```lua
["workshop-000000000"]={ configuration_options={ }, enabled=true }
```

`000000000` 替换为 Workshop ID。

## 配置选项

使用每个 Mod 的 `configuration_options` 字典设置选项：

```lua
["workshop-000000000"]={
  configuration_options={ },
  enabled=true
}
```

不同 Mod 的选项由作者定义，不能假设所有 Mod 使用相同配置。

## 从本地游戏生成配置

1. 打开游戏并进入“游玩”。
2. 选择“创建游戏”，在 Mod 页面启用并配置需要的 Mod。
3. 生成世界并退出。
4. 复制生成的 `modoverrides.lua` 到服务器的 `DSTClusterConfig/mods/modoverrides.lua`。
5. 将需要下载的 Workshop ID 写入 `dedicated_server_mods_setup.lua`。

常见位置：

- Linux/macOS：`~/.klei/DoNotStarveTogether/Cluster_N/Master/modoverrides.lua`
- Windows：`文档/Klei/DoNotStarveTogether/Cluster_N/Master/modoverrides.lua`

服务器 Mod 与客户端 Mod 不是同一个目录。启用新 Mod 后，建议先备份世界并观察两个分片日志。
