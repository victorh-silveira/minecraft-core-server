COMPOSE := docker compose
SERVICE := mc-server
CONTAINER := minecraft_core_server
ENV_FILE := .env
COMPOSE_FLAGS := --env-file $(ENV_FILE)

.PHONY: docker-help docker-env-check docker-sync-mods docker-config docker-pull docker-build docker-up docker-build-up docker-start docker-stop docker-restart docker-down docker-remove docker-clean docker-nuke docker-logs docker-logs-tail docker-ps docker-sh docker-exec docker-stats docker-attach docker-top docker-inspect docker-health

docker-help:
	@echo "Comandos Minecraft Server (Docker Compose)"
	@echo ""
	@echo "  make docker-env-check    Verifica se $(ENV_FILE) existe"
	@echo "  make docker-sync-mods    Baixa mods do mods-manifest.json"
	@echo "  make docker-config       Valida docker-compose.yml + .env"
	@echo "  make docker-pull         Baixa imagem mais recente (sem cache local)"
	@echo "  make docker-build        Pull + build --no-cache (se houver Dockerfile)"
	@echo "  make docker-up           Sobe o servidor (pull always, force-recreate)"
	@echo "  make docker-build-up     sync-mods + build + up"
	@echo "  make docker-start        Inicia containers parados"
	@echo "  make docker-stop         Para containers sem remover"
	@echo "  make docker-restart      Reinicia o servico $(SERVICE)"
	@echo "  make docker-down         Para e remove containers/rede"
	@echo "  make docker-remove       down + remove imagens do projeto"
	@echo "  make docker-clean        Remove containers, rede e imagens locais"
	@echo "  make docker-nuke         clean + prune do Docker (cuidado)"
	@echo "  make docker-logs         Logs em tempo real (-f)"
	@echo "  make docker-logs-tail    Ultimas 200 linhas dos logs"
	@echo "  make docker-ps           Lista containers do compose"
	@echo "  make docker-sh           Shell interativo no container"
	@echo "  make docker-exec CMD=... Executa comando no container"
	@echo "  make docker-stats        Uso de CPU/RAM em tempo real"
	@echo "  make docker-attach       Anexa stdin/stdout ao container"
	@echo "  make docker-top          Processos dentro do container"
	@echo "  make docker-inspect      JSON de inspecao do container"
	@echo "  make docker-health       Status rapido do servidor"

docker-env-check:
	@test -f $(ENV_FILE) || (echo "Arquivo $(ENV_FILE) nao encontrado. Copie .env.example para .env" && exit 1)

docker-sync-mods:
	python scripts/sync_mods.py

docker-config: docker-env-check
	$(COMPOSE) $(COMPOSE_FLAGS) config

docker-pull: docker-env-check
	$(COMPOSE) $(COMPOSE_FLAGS) pull --ignore-pull-failures $(SERVICE)

docker-build: docker-env-check docker-pull
	BUILD_DATE=$$(date -u +%Y-%m-%dT%H:%M:%SZ) VCS_REF=$$(git rev-parse --short HEAD 2>/dev/null || echo local) \
		$(COMPOSE) $(COMPOSE_FLAGS) build --no-cache --pull $(SERVICE)

docker-up: docker-env-check docker-sync-mods
	$(COMPOSE) $(COMPOSE_FLAGS) up -d --build --force-recreate --renew-anon-volumes $(SERVICE)

docker-build-up: docker-build docker-up

docker-start: docker-env-check
	$(COMPOSE) $(COMPOSE_FLAGS) start $(SERVICE)

docker-stop: docker-env-check
	$(COMPOSE) $(COMPOSE_FLAGS) stop $(SERVICE)

docker-restart: docker-env-check
	$(COMPOSE) $(COMPOSE_FLAGS) restart $(SERVICE)

docker-down: docker-env-check
	$(COMPOSE) $(COMPOSE_FLAGS) down --remove-orphans

docker-remove: docker-env-check
	$(COMPOSE) $(COMPOSE_FLAGS) down --remove-orphans --rmi local

docker-clean: docker-env-check
	$(COMPOSE) $(COMPOSE_FLAGS) down --remove-orphans --rmi local -v
	docker rm -f $(CONTAINER) 2>/dev/null || true
	docker rmi -f minecraft-core-server:latest 2>/dev/null || true

docker-nuke: docker-clean
	docker system prune -af --volumes

docker-logs: docker-env-check
	$(COMPOSE) $(COMPOSE_FLAGS) logs -f $(SERVICE)

docker-logs-tail: docker-env-check
	$(COMPOSE) $(COMPOSE_FLAGS) logs --tail=200 $(SERVICE)

docker-ps: docker-env-check
	$(COMPOSE) $(COMPOSE_FLAGS) ps -a

docker-sh: docker-env-check
	docker exec -it $(CONTAINER) /bin/bash || docker exec -it $(CONTAINER) /bin/sh

docker-exec: docker-env-check
	@test -n "$(CMD)" || (echo "Use: make docker-exec CMD='comando'" && exit 1)
	docker exec -it $(CONTAINER) $(CMD)

docker-stats: docker-env-check
	docker stats $(CONTAINER)

docker-attach: docker-env-check
	docker attach $(CONTAINER)

docker-top: docker-env-check
	docker top $(CONTAINER)

docker-inspect: docker-env-check
	docker inspect $(CONTAINER)

docker-health: docker-env-check
	@$(COMPOSE) $(COMPOSE_FLAGS) ps $(SERVICE)
	@docker inspect -f 'Status={{.State.Status}} Health={{if .State.Health}}{{.State.Health.Status}}{{else}}n/a{{end}}' $(CONTAINER) 2>/dev/null || echo "Container $(CONTAINER) nao encontrado"

.DEFAULT_GOAL := docker-help
