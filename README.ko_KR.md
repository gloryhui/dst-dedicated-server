# Don't Starve Together 전용 서버

Docker로 Don't Starve Together Linux 전용 서버를 운영하기 위한 프로젝트입니다.

이미지에는 SteamCMD, 실행 라이브러리, 시작 스크립트만 포함됩니다. Steam App `343050`의 게임 파일은 컨테이너 시작 시 영구 볼륨에 다운로드하며 현재 64비트 서버 바이너리를 우선 실행합니다. 지원 컨테이너 플랫폼은 `linux/amd64`입니다.

## 다른 언어

- [English](README.md)
- [简体中文](README.zh_CN.md)
- [日本語](README.ja_JP.md)
- 한국어 (현재 페이지)

## 빠른 시작

Docker Engine 또는 Docker Desktop, Compose v2, Git, amd64 호스트가 필요합니다. ARM 호스트에서는 amd64 에뮬레이션을 사용할 수 있습니다.

```bash
git clone https://github.com/mathielo/dst-dedicated-server.git
cd dst-dedicated-server
```

[Klei Server Token 페이지](https://accounts.klei.com/account/game/servers?game=DontStarveTogether)에서 Token을 생성한 뒤 값만 `DSTClusterConfig/cluster_token.txt`에 저장합니다.

```bash
docker compose up -d --build
docker compose ps
docker compose logs -f
```

컨테이너를 처음 시작할 때 전체 전용 서버를 다운로드하고, 이후에도 시작할 때마다 SteamCMD로 업데이트를 확인합니다. 실패 시 최대 3회 시도하며 업데이트 실패 시 서버를 시작하지 않습니다. 실행 중에는 주기적으로 확인하지 않습니다. `UPDATE_SERVER=false`는 설치된 서버의 업데이트를 건너뛰지만 빈 볼륨에는 최초 다운로드가 필요합니다.

Master와 Caves는 별도의 영구 볼륨을 사용하여 같은 게임 파일을 동시에 업데이트하지 않습니다. 컨테이너 재생성이나 `docker compose down` 후에도 유지되며 `docker compose down -v`는 삭제합니다. 게임 업데이트를 위해 이미지를 다시 빌드할 필요는 없습니다. 이전 구성에서 이전할 때 새 볼륨에 최초 다운로드가 필요합니다.

## 포트와 네트워크

| Shard | 포트 |
| --- | --- |
| Master | `10999/udp` |
| Caves | `10998/udp` |

호스트 방화벽, 클라우드 보안 그룹, NPS 등에서 두 UDP 포트를 모두 전달하세요. 게임 포트를 TCP로 전달하면 안 됩니다. DNS는 이름만 제공하며 중계 기능이 없습니다. 해외 플레이어가 직접 연결하지 못하면 UDP를 지원하는 L4 릴레이를 사용하세요.

Klei와 Steam 인증 및 등록 연결도 필요합니다. 릴레이는 게임 포트를 전달할 수 있지만 Klei 인증이나 Steam 접속을 대신하지 않습니다.

## 최소 배포

Git에서 제외된 `deployment/` 디렉터리에는 기본 월드, Master+Caves, Mod 없음의 최소 구성이 있습니다.

```bash
cd deployment
docker compose up -d --build
```

## 설정

- `DSTClusterConfig/cluster.ini`: 이름, 비밀번호, 인원, 언어, 네트워크
- `DSTClusterConfig/cluster_token.txt`: 비밀 Klei Token. Git에 커밋하지 마세요.
- `DSTClusterConfig/*/leveldataoverride.lua`: 월드 생성 설정
- `DSTClusterConfig/mods/`: Mod 설정

## 이미지 배포

플레이어와 가까운 GHCR, Docker Hub, Alibaba Cloud ACR, Harbor 등에 동일한 immutable tag를 배포할 수 있습니다.

```bash
docker buildx build --platform linux/amd64 \
  -t ghcr.io/OWNER/dst-dedicated-server:VERSION \
  --push .
```

이미지 미러는 이미지 다운로드 속도만 개선하며 매칭, Klei 인증, 게임 UDP 지연을 개선하지 않습니다. Token, 세이브 데이터, `deployment/`는 이미지에 넣지 마세요.

## 문제 해결

- 서버 버전이 오래됨: 재시작 후 SteamCMD 로그 확인.
- 서버가 목록에 없음: Token, UDP 포트, 클라우드 보안 그룹, NPS, Klei/Steam 외부 연결 확인.
- Master와 Caves가 연결되지 않음: `master_ip = dst_master`, `cluster_key`, Docker 네트워크 확인.
- 저장 실패: 바인드 마운트 소유권과 쓰기 권한 확인.

자세한 관리 방법은 [docs/ManagingTheServer.md](docs/ManagingTheServer.md)를 참고하세요.

Docker를 사용하지 않는 네이티브 Linux 절차와 배포판별 의존성은 [docs/NativeLinux.md](docs/NativeLinux.md)를 참고하세요. 재현성과 유지보수를 위해 Docker를 권장합니다.

라이선스: MIT.
