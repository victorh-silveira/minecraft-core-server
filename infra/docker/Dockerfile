# syntax=docker/dockerfile:1.7

FROM golang:1.26.6-alpine@sha256:3889b425f035be855a72fb4755265311293b6d414521f0a519d819df32222d83 AS security-builder

SHELL ["/bin/ash", "-eo", "pipefail", "-c"]

ARG TARGETOS
ARG TARGETARCH

RUN apk add --no-cache git=2.54.0-r0

WORKDIR /build/rcon-cli

RUN --mount=type=cache,target=/go/pkg/mod \
    --mount=type=cache,target=/root/.cache/go-build \
    git clone --filter=blob:none https://github.com/itzg/rcon-cli.git . \
    && git checkout --detach ffe5ac4eab6b0956f743683e4d7e8df380893006 \
    && go mod edit -require=golang.org/x/text@v0.39.0 \
    && go mod tidy \
    && CGO_ENABLED=0 GOOS="${TARGETOS}" GOARCH="${TARGETARCH}" go build -trimpath -ldflags="-s -w" -o /out/rcon-cli .

WORKDIR /build/mc-monitor

RUN --mount=type=cache,target=/go/pkg/mod \
    --mount=type=cache,target=/root/.cache/go-build \
    git clone --filter=blob:none https://github.com/itzg/mc-monitor.git . \
    && git checkout --detach e4c239b12b6546166ce4a5eb08543c350dc63f4b \
    && go mod edit -require=google.golang.org/grpc@v1.83.2 \
    && go mod tidy \
    && CGO_ENABLED=0 GOOS="${TARGETOS}" GOARCH="${TARGETARCH}" go build -trimpath -ldflags="-s -w" -o /out/mc-monitor .

RUN mkdir -p /out/jars \
    && wget -q -O /out/jars/micrometer-core-1.16.5.jar https://repo.maven.apache.org/maven2/io/micrometer/micrometer-core/1.16.6/micrometer-core-1.16.6.jar \
    && wget -q -O /out/jars/micrometer-observation-1.16.5.jar https://repo.maven.apache.org/maven2/io/micrometer/micrometer-observation/1.16.6/micrometer-observation-1.16.6.jar \
    && wget -q -O /out/jars/micrometer-commons-1.16.5.jar https://repo.maven.apache.org/maven2/io/micrometer/micrometer-commons/1.16.6/micrometer-commons-1.16.6.jar \
    && wget -q -O /out/jars/bcprov-jdk18on-1.84.jar https://repo.maven.apache.org/maven2/org/bouncycastle/bcprov-jdk18on/1.85/bcprov-jdk18on-1.85.jar \
    && wget -q -O /out/jars/scala-library-2.13.1.jar https://repo.maven.apache.org/maven2/org/scala-lang/scala-library/2.13.9/scala-library-2.13.9.jar \
    && wget -q -O /out/jars/jackson-core-3.1.3.jar https://repo.maven.apache.org/maven2/tools/jackson/core/jackson-core/3.1.4/jackson-core-3.1.4.jar \
    && wget -q -O /out/jars/jackson-databind-3.1.3.jar https://repo.maven.apache.org/maven2/tools/jackson/core/jackson-databind/3.1.4/jackson-databind-3.1.4.jar \
    && echo "1957ef2deaffbc1fb98cebfd0f5b3109ecf19c994d7e5378598c20747ba8d68b  /out/jars/micrometer-core-1.16.5.jar" | sha256sum -c - \
    && echo "4c0826d5e7c8522a8e111470b4e77f77b0a10f520eb5502ddd143fdbcedb2340  /out/jars/micrometer-observation-1.16.5.jar" | sha256sum -c - \
    && echo "45aff76226830db257f4bc39a5bcff83d633e572fee9dc4e45cfa12af9a0a49a  /out/jars/micrometer-commons-1.16.5.jar" | sha256sum -c - \
    && echo "20af26bf6060bb8005cc2389916812c1e0e998dc48d2ced7131b89461b54cff7  /out/jars/bcprov-jdk18on-1.84.jar" | sha256sum -c - \
    && echo "317e0cd80aa8b0ce9e98d154053d9a0f5acc63854b68ca5522d3e017c68dc8e5  /out/jars/scala-library-2.13.1.jar" | sha256sum -c - \
    && echo "3bda1cd6eff0a8d47bdfcaeae7c2bd5311d6c8ed494ef5f3e51029bb44aa9bdf  /out/jars/jackson-core-3.1.3.jar" | sha256sum -c - \
    && echo "14034bfdf392b6ebec1b4bb6c1de29d604f0aa97251259a19d5f19af8719bb20  /out/jars/jackson-databind-3.1.3.jar" | sha256sum -c -

FROM itzg/minecraft-server:java25@sha256:83c076bb24c87e5a5cf5d884d180c7be8896a4c1d5963d74a39a4325401cc2ba

ARG BASE_IMAGE=itzg/minecraft-server:java25@sha256:83c076bb24c87e5a5cf5d884d180c7be8896a4c1d5963d74a39a4325401cc2ba
ARG BUILD_DATE=unknown
ARG VCS_REF=local
ARG IMAGE_VERSION=0.1.0

LABEL org.opencontainers.image.title="Servidor Minecraft Core"
LABEL org.opencontainers.image.description="Servidor Minecraft Forge 26.3 sem mods com Clean Architecture"
LABEL org.opencontainers.image.version="${IMAGE_VERSION}"
LABEL org.opencontainers.image.created="${BUILD_DATE}"
LABEL org.opencontainers.image.revision="${VCS_REF}"
LABEL org.opencontainers.image.vendor="minecraft-server"
LABEL org.opencontainers.image.base.name="${BASE_IMAGE}"
LABEL org.opencontainers.image.source="https://github.com/victorh-silveira/minecraft-core-server"

USER 0

RUN rm -f /usr/local/bin/gosu /usr/local/bin/restify

COPY --from=security-builder --chmod=0755 /out/rcon-cli /usr/local/bin/rcon-cli
COPY --from=security-builder --chmod=0755 /out/mc-monitor /usr/local/bin/mc-monitor
COPY --from=security-builder --chmod=0644 /out/jars/ /usr/share/mc-image-helper-1.70.1/lib/

USER 1000

COPY --chown=minecraft:minecraft app/runtime/configs/server.properties /templates/server.properties
COPY --chown=minecraft:minecraft app/runtime/configs/server-icon.png /templates/server-icon.png
COPY --chown=minecraft:minecraft app/runtime/mods/mods-manifest.json /templates/mods-manifest.json

WORKDIR /data

STOPSIGNAL SIGTERM

EXPOSE 25565/tcp
EXPOSE 25575/tcp

ENV UID=1000 \
    GID=1000 \
    ENABLE_RCON=true \
    USE_AIKAR_FLAGS=true \
    SYNC_CHUNK_WRITES=true

HEALTHCHECK --interval=30s --timeout=10s --start-period=180s --retries=5 \
    CMD ["mc-health"]

VOLUME ["/data"]
