# Don't Starve Together 専用サーバー

Docker で Don't Starve Together の Linux 専用サーバーを運用するためのプロジェクトです。

SteamCMD で Steam App `343050` をインストールし、64-bit サーバーを優先して起動します。対応コンテナプラットフォームは `linux/amd64` です。

## 他の言語

- [English](README.md)
- [简体中文](README.zh_CN.md)
- 日本語（このページ）
- [한국어](README.ko_KR.md)

## クイックスタート

Docker Engine または Docker Desktop、Compose v2、Git、amd64 ホストが必要です。ARM ホストでは amd64 エミュレーションを使用できます。

```bash
git clone https://github.com/mathielo/dst-dedicated-server.git
cd dst-dedicated-server
```

[Klei の Server Token ページ](https://accounts.klei.com/account/game/servers?game=DontStarveTogether)で Token を作成し、Token の値だけを `DSTClusterConfig/cluster_token.txt` に保存します。

```bash
docker compose up -d --build
docker compose ps
docker compose logs -f
```

初回ビルドではゲームサーバー全体をダウンロードします。起動時の SteamCMD 更新は一時的な失敗に対して 3 回再試行します。

## ポートとネットワーク

| Shard | ポート |
| --- | --- |
| Master | `10999/udp` |
| Caves | `10998/udp` |

ファイアウォール、クラウドのセキュリティグループ、NPS などで両方の UDP ポートを転送してください。ゲーム通信を TCP で転送してはいけません。DNS は名前解決だけであり、中継にはなりません。海外のプレイヤーが接続できない場合は UDP 対応の L4 リレーを使用してください。

Klei と Steam の認証・登録通信は別途必要です。リレーはゲームポートを転送できますが、Klei 認証や Steam へのアクセスを代替するものではありません。

## 最小構成

Git 管理外の `deployment/` ディレクトリには、デフォルトワールド、Master+Caves、Mod なしの最小構成があります。

```bash
cd deployment
docker compose up -d --build
```

## 設定

- `DSTClusterConfig/cluster.ini`：名前、パスワード、人数、言語、ネットワーク
- `DSTClusterConfig/cluster_token.txt`：秘密の Klei Token。Git にコミットしない
- `DSTClusterConfig/*/leveldataoverride.lua`：ワールド生成
- `DSTClusterConfig/mods/`：Mod

## イメージ配布

プレイヤーに近い GHCR、Docker Hub、Alibaba Cloud ACR、Harbor などへ同じ immutable tag を公開できます。

```bash
docker buildx build --platform linux/amd64 \
  -t ghcr.io/OWNER/dst-dedicated-server:VERSION \
  --push .
```

イメージミラーはダウンロード速度を改善しますが、マッチング、Klei 認証、ゲーム UDP の遅延は改善しません。Token、セーブデータ、`deployment/` はイメージに含めないでください。

## トラブルシューティング

- 古いバージョン：再起動して SteamCMD ログを確認。
- サーバーが表示されない：Token、UDP ポート、クラウド防火墙、NPS、Klei/Steam への外向き通信を確認。
- Master と Caves が接続しない：`master_ip = dst_master`、`cluster_key`、Docker ネットワークを確認。
- セーブに失敗する：バインドマウントの所有者と書き込み権限を確認。

詳しい管理方法は [docs/ManagingTheServer.md](docs/ManagingTheServer.md) を参照してください。

Docker を使わないネイティブ Linux の手順（未検証のディストリビューションを含む）は [docs/NativeLinux.md](docs/NativeLinux.md) を参照してください。再現性と保守性のため Docker を推奨します。

ライセンス：MIT。
