FROM debian:bookworm-slim

LABEL maintainer="Caio Mathielo <mathielo@gmail.com>"
LABEL description="Don't Starve Together dedicated server"
LABEL source="https://github.com/mathielo/dst-dedicated-server"

ARG DST_APP_ID=343050
ENV DST_INSTALL_DIR=/home/dst/server_dst

WORKDIR /home/dst

# SteamCMD still includes a 32-bit bootstrapper, while current DST also ships
# a 64-bit dedicated-server binary. Keep both runtimes available.
RUN set -eux; \
    dpkg --add-architecture i386; \
    apt-get update; \
    DEBIAN_FRONTEND=noninteractive apt-get install --no-install-recommends -y \
        bash \
        ca-certificates \
        curl \
        libc6:i386 \
        lib32gcc-s1 \
        lib32stdc++6 \
        libcurl3-gnutls \
        libcurl3-gnutls:i386 \
        libcurl4 \
        libcurl4:i386; \
    curl --fail --silent --show-error --location --retry 5 --retry-all-errors --retry-delay 2 \
        https://media.steampowered.com/client/installer/steamcmd_linux.tar.gz | tar -xzf -; \
    useradd --create-home --shell /bin/bash dst; \
    chown -R dst:dst /home/dst; \
    apt-get clean; \
    rm -rf /var/lib/apt/lists/*

USER dst
RUN mkdir -p "$HOME/.klei/DoNotStarveTogether" "$DST_INSTALL_DIR/mods"; \
    for attempt in 1 2 3; do \
        if ./steamcmd.sh \
            +@ShutdownOnFailedCommand 1 \
            +@NoPromptForPassword 1 \
            +force_install_dir "$DST_INSTALL_DIR" \
            +login anonymous \
            +app_update "$DST_APP_ID" validate \
            +quit; then \
            exit 0; \
        fi; \
        echo "SteamCMD update failed (attempt $attempt/3), retrying..." >&2; \
        sleep $((attempt * 5)); \
    done; \
    exit 1

VOLUME ["/home/dst/.klei/DoNotStarveTogether", "/home/dst/server_dst/mods"]

COPY --chown=dst:dst --chmod=755 start-container-server.sh /home/dst/start-container-server.sh
ENTRYPOINT ["/home/dst/start-container-server.sh"]
