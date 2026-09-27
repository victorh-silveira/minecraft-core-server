# syntax=docker/dockerfile:1.7

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

COPY --chown=minecraft:minecraft app/runtime/configs/server.properties /templates/server.properties
COPY --chown=minecraft:minecraft app/runtime/mods/mods-manifest.json /templates/mods-manifest.json

RUN mkdir -p /templates/mods /templates/plugins /data/world /data/mods /data/plugins /data/logs /data/database \
    && chown -R minecraft:minecraft /templates /data \
    && chmod -R g+rwX /data /templates

USER 1000

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

VOLUME ["/data/world", "/data/mods", "/data/plugins", "/data/logs", "/data/database"]
