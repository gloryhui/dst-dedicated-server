# 服务器性能

## 推荐资源

标准地上+洞穴服务器由两个分片组成：

- 每个分片至少准备 1 个可用 CPU 核心
- 每个分片建议准备约 1 GiB RAM
- 使用稳定、低丢包并且上传带宽充足的网络
- 使用 SSD，尤其是世界生成和每日保存时更稳定
- 不需要 GPU

DST 分片主要依赖单核性能，CPU 核心数量很多并不等于单个分片性能更好。

## 监控

Docker：

```bash
docker stats dst_master dst_caves
docker compose logs -f dst_master dst_caves
```

重点观察：

- CPU 长时间接近 100%
- 内存持续增长或被系统 OOM
- 保存时出现卡顿
- 日志出现 `Failed to save file`、`timeout` 或分片断开

原生 Linux 可以使用 `top`、`htop`、`free -h`、`iostat` 和 `journalctl`。

## 网络与选址

如果玩家来自多个地区，服务器应尽量位于网络路径较好的中间位置。域名不会降低延迟；跨地区访问困难时，应使用支持 UDP 的四层中转或 VPN。

NPS 等穿透服务必须转发：

- Master：`10999/udp`
- Caves：`10998/udp`

不要把游戏端口配置成 TCP。

## 主机选择

Linux Server 通常比带图形界面的桌面系统占用更少资源。VPS 应避免 CPU credits 限制，否则玩家进入后可能出现持续性能不足。

本地电脑同时运行客户端和服务端时，需要为操作系统、游戏客户端和两个服务分片共同预留 CPU、内存和上传带宽。
