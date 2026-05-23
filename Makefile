COMPOSE := docker compose
SERVICE := mc-server
CONTAINER := minecraft_core_server
ENV_FILE := .env
COMPOSE_FLAGS := --env-file $(ENV_FILE)

.PHONY: docker-help docker-env-check docker-sync-mods docker-build docker-pull docker-up docker-build-up docker-down docker-restart docker-logs docker-sh docker-clean docker-test docker-nuke

docker-help:
	@echo "Comandos Minecraft Server (Docker Compose)"
	@echo ""
	@echo "  make docker-build-up     Sync mods, build e sobe o servidor"
	@echo "  make docker-up           Sobe o servidor (build + recreate)"
	@echo "  make docker-down         Para e remove containers/rede"
	@echo "  make docker-restart      Reinicia o servico"
	@echo "  make docker-sync-mods    Baixa mods do mods-manifest.json"
	@echo "  make docker-logs         Logs em tempo real"
	@echo "  make docker-sh           Shell no container"
	@echo "  make docker-clean        Remove containers e imagens locais"
	@echo "  make docker-test         Roda scripts/bash/test-docker.sh no ambiente atual"
	@echo "  make docker-nuke         Apaga TODO o Docker no WSL (com confirmacao s/N)"

docker-env-check:
	@test -f $(ENV_FILE) || (echo "Arquivo $(ENV_FILE) nao encontrado. Copie .env.example para .env" && exit 1)

docker-sync-mods:
	python scripts/python/sync_mods.py

docker-pull: docker-env-check
	$(COMPOSE) $(COMPOSE_FLAGS) pull --ignore-pull-failures $(SERVICE)

docker-build: docker-env-check docker-pull
	BUILD_DATE=$$(date -u +%Y-%m-%dT%H:%M:%SZ) VCS_REF=$$(git rev-parse --short HEAD 2>/dev/null || echo local) \
		$(COMPOSE) $(COMPOSE_FLAGS) build --no-cache --pull $(SERVICE)

docker-up: docker-env-check docker-sync-mods
	$(COMPOSE) $(COMPOSE_FLAGS) up -d --build --force-recreate --renew-anon-volumes $(SERVICE)

docker-build-up: docker-build docker-up

docker-down: docker-env-check
	$(COMPOSE) $(COMPOSE_FLAGS) down --remove-orphans

docker-restart: docker-env-check
	$(COMPOSE) $(COMPOSE_FLAGS) restart $(SERVICE)

docker-logs: docker-env-check
	$(COMPOSE) $(COMPOSE_FLAGS) logs -f $(SERVICE)

docker-sh: docker-env-check
	docker exec -it $(CONTAINER) /bin/bash || docker exec -it $(CONTAINER) /bin/sh

docker-clean: docker-env-check
	$(COMPOSE) $(COMPOSE_FLAGS) down --remove-orphans --rmi local -v
	docker rm -f $(CONTAINER) 2>/dev/null || true
	docker rmi -f minecraft-core-server:latest 2>/dev/null || true

docker-test: docker-env-check
	bash scripts/bash/test-docker.sh

docker-nuke:
	bash scripts/bash/docker-nuke.sh

.DEFAULT_GOAL := docker-help
