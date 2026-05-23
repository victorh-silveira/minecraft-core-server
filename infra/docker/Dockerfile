# syntax=docker/dockerfile:1.7

ARG BASE_IMAGE=itzg/minecraft-server:java21

FROM ${BASE_IMAGE}

ARG BASE_IMAGE
ARG BUILD_DATE=unknown
ARG VCS_REF=local
ARG IMAGE_VERSION=0.1.0

LABEL org.opencontainers.image.title="Minecraft Core Server"
LABEL org.opencontainers.image.description="Servidor Minecraft Fabric com Clean Architecture e mods versionados"
LABEL org.opencontainers.image.version="${IMAGE_VERSION}"
LABEL org.opencontainers.image.created="${BUILD_DATE}"
LABEL org.opencontainers.image.revision="${VCS_REF}"
LABEL org.opencontainers.image.vendor="minecraft-server"
LABEL org.opencontainers.image.base.name="${BASE_IMAGE}"
LABEL org.opencontainers.image.source="https://github.com/local/minecraft-server"

USER root

COPY --chown=minecraft:minecraft app/src/application/configs/server.properties /templates/server.properties
COPY --chown=minecraft:minecraft app/src/interface/mods/mods-manifest.json /templates/mods-manifest.json

RUN mkdir -p /templates/mods /templates/plugins /data/world /data/mods /data/plugins /data/logs /data/database \
    && chown -R minecraft:minecraft /templates /data \
    && chmod -R g+rwX /data /templates

USER minecraft

WORKDIR /data

EXPOSE 25565/tcp
EXPOSE 25575/tcp

ENV UID=1000 \
    GID=1000 \
    ENABLE_RCON=true \
    USE_AIKAR_FLAGS=true \
    SYNC_CHUNK_WRITES=true

HEALTHCHECK --interval=30s --timeout=10s --start-period=180s --retries=5 \
    CMD mc-health || exit 1

VOLUME ["/data/world", "/data/mods", "/data/plugins", "/data/logs", "/data/database"]
