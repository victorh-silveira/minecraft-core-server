# ==============================================================================
#                 MINECRAFT CORE SERVER - MAKEFILE
# ==============================================================================

SHELL := /bin/bash

REPO_ROOT := $(CURDIR)
APP_DIR := app
COMPOSE_FILE := infra/docker/docker-compose.yml
ENV_FILE := infra/docker/.env
COMPOSE := docker compose -f $(COMPOSE_FILE)
COMPOSE_FLAGS := --env-file $(ENV_FILE)
SERVICE := mc-server
CONTAINER := minecraft_core_server
TF_LIVE := infra/terraform/live/prod
OPS := python $(APP_DIR)/scripts/operations/clean_workspace.py
DOCKER_LOGS_TAIL ?= all

RUN_LINUX := bash $(APP_DIR)/scripts/bash/run-in-linux-env.sh
DEV_ENV := $(RUN_LINUX) bash $(APP_DIR)/scripts/bash/run-in-dev-env.sh
CI_INFRA := $(RUN_LINUX) bash $(APP_DIR)/scripts/bash/ci-infra-local.sh

GREEN  := \033[1;32m
YELLOW := \033[1;33m
BLUE   := \033[1;34m
CYAN   := \033[1;36m
RED    := \033[1;31m
RESET  := \033[0m

.DEFAULT_GOAL := help

.PHONY: help app-install app-lint app-validate app-test app-security app-build app-run app-clean app-setup \
	app-pre-commit app-pre-commit-run pre-commit pre-commit-install \
	dev-deps clean \
	ci-fmt ci-lint ci-validate-infra ci-infra ci-pre-push ci-test ci-validate \
	terraform-plan \
	docker-env-check docker-sync-mods docker-build docker-up \
	docker-down docker-restart docker-logs docker-ps docker-sh docker-clean \
	docker-rebuild docker-smoke docker-test \
	k8s-deploy k8s-apply k8s-annotate k8s-test

help:
	@echo -e "$(BLUE)========================================================================$(RESET)"
	@echo -e "$(GREEN)                   MINECRAFT CORE SERVER - MENU DE AJUDA                $(RESET)"
	@echo -e "$(BLUE)========================================================================$(RESET)"
	@echo -e "Uso: $(CYAN)make <comando>$(RESET)"
	@echo -e ""
	@echo -e "$(YELLOW)Python:$(RESET) WSL + .venv ($(APP_DIR)/requirements*.txt)"
	@echo -e ""
	@echo -e "$(YELLOW)App:$(RESET)"
	@echo -e "  $(GREEN)app-clean$(RESET)            - Limpa caches, artefactos e logs locais"
	@echo -e "  $(GREEN)app-install$(RESET)          - Instala dependencias no .venv"
	@echo -e "  $(GREEN)app-lint$(RESET)             - Lint crash-first (Python, Docker, K8s, Terraform, GitHub, Scripts)"
	@echo -e "  $(GREEN)app-pre-commit$(RESET)       - Instala e valida githooks pre-commit"
	@echo -e "  $(GREEN)app-pre-commit-run$(RESET)   - Executa pre-commit em todos os arquivos"
	@echo -e "  $(GREEN)app-run$(RESET)              - Sync de mods via manifesto (run.py)"
	@echo -e "  $(GREEN)app-security$(RESET)         - Seguranca crash-first da matriz"
	@echo -e "  $(GREEN)app-setup$(RESET)            - app-install + hooks git"
	@echo -e "  $(GREEN)app-test$(RESET)             - Testes crash-first da matriz + cobertura 100%%"
	@echo -e "  $(GREEN)app-validate$(RESET)         - Validate crash-first da matriz"
	@echo -e "  $(GREEN)app-build$(RESET)            - Build crash-first da matriz"
	@echo -e ""
	@echo -e "$(YELLOW)Docker:$(RESET)"
	@echo -e "  $(GREEN)docker-clean$(RESET)         - $(RED)DESTRUTIVO$(RESET): remove containers, redes e volumes do projeto"
	@echo -e "  $(GREEN)docker-down$(RESET)          - Para os containers (preserva bind mounts)"
	@echo -e "  $(GREEN)docker-logs$(RESET)          - Exibe logs (DOCKER_LOGS_TAIL=..., F=1)"
	@echo -e "  $(GREEN)docker-ps$(RESET)            - Exibe o status atual dos containers"
	@echo -e "  $(GREEN)docker-rebuild$(RESET)       - Rebuild sem cache, recreate (preserva mundo/dados)"
	@echo -e "  $(GREEN)docker-restart$(RESET)       - Reinicia o servico (preserva dados)"
	@echo -e "  $(GREEN)docker-sh$(RESET)            - Shell no container mc-server"
	@echo -e "  $(GREEN)docker-smoke$(RESET)         - Smoke em 127.0.0.1 e 192.168.0.50 (SMOKE_LAN_HOST)"
	@echo -e "  $(GREEN)docker-sync-mods$(RESET)     - Baixa JARs via manifesto"
	@echo -e "  $(GREEN)docker-up$(RESET)            - Sync mods, build e sobe o servidor Fabric"
	@echo -e ""
	@echo -e "$(YELLOW)Kubernetes:$(RESET)"
	@echo -e "  $(GREEN)k8s-annotate$(RESET)         - Atualiza annotations de conectividade"
	@echo -e "  $(GREEN)k8s-apply$(RESET)            - Deploy AKS exigindo IMAGE_DIGEST=sha256:..."
	@echo -e "  $(GREEN)k8s-deploy$(RESET)           - Deploy AKS (IMAGE_DIGEST, RCON_PASSWORD, MINECRAFT_WHITELIST)"
	@echo -e "  $(GREEN)k8s-test$(RESET)             - Diagnostico pos-deploy no AKS"
	@echo -e "$(BLUE)========================================================================$(RESET)"

# ------------------------------------------------------------------------------
# App / qualidade
# ------------------------------------------------------------------------------

app-install:
	$(DEV_ENV) python -c "import ruff, pytest, pre_commit, mypy; print('Dependencias Python OK')"

app-lint: app-install
	$(DEV_ENV) bash -lc "$(OPS) --area all --stage lint"

app-validate: app-install
	$(DEV_ENV) bash -lc "$(OPS) --area all --stage validate"

app-test: app-install
	$(DEV_ENV) bash -lc "$(OPS) --area all --stage test --coverage-fail-under 100"

app-security: app-install
	$(DEV_ENV) bash -lc "$(OPS) --area all --stage security"

app-build: app-install
	$(DEV_ENV) bash -lc "$(OPS) --area all --stage build"

app-clean: app-install
	$(DEV_ENV) bash -lc "$(OPS) --stage clean"

app-run: app-install
	$(DEV_ENV) bash -lc "python run.py"

app-pre-commit: app-install
	$(DEV_ENV) pre-commit install
	$(DEV_ENV) pre-commit install --hook-type commit-msg
	@chmod +x linters/git-hooks/commit-msg linters/git-hooks/commitlint-fast.sh 2>/dev/null || true

app-pre-commit-run: app-install
	$(DEV_ENV) pre-commit run --all-files -c .pre-commit-config.yaml

app-setup: app-install app-pre-commit

pre-commit: app-pre-commit
pre-commit-install: app-pre-commit
dev-deps: app-install
clean: app-clean

# ------------------------------------------------------------------------------
# CI / Terraform
# ------------------------------------------------------------------------------

ci-fmt: app-install
	$(CI_INFRA) fmt
	$(DEV_ENV) python -m ruff format --config $(APP_DIR)/pyproject.toml $(APP_DIR)/src $(APP_DIR)/tests $(APP_DIR)/scripts run.py

ci-lint: app-pre-commit-run

ci-validate-infra:
	$(CI_INFRA) validate

ci-infra: ci-fmt
	$(CI_INFRA) lint
	$(CI_INFRA) security
	$(CI_INFRA) test
	$(CI_INFRA) validate
	$(CI_INFRA) build

ci-pre-push: app-lint app-security app-test app-validate app-build

ci-test: app-test

ci-validate: app-validate app-test app-security

terraform-plan:
	@test -f $(TF_LIVE)/terraform.tfvars || (echo "Crie $(TF_LIVE)/terraform.tfvars a partir do .example" && exit 1)
	$(RUN_LINUX) bash -lc "cd $(TF_LIVE) && terraform init -input=false && terraform plan -input=false"

# ------------------------------------------------------------------------------
# Docker
# ------------------------------------------------------------------------------

docker-env-check:
	@test -f $(ENV_FILE) || (echo "Copie infra/docker/.env.example para $(ENV_FILE)" && exit 1)

docker-sync-mods: app-run

docker-build: docker-env-check
	$(RUN_LINUX) bash -lc "BUILD_DATE=\$$(date -u +%Y-%m-%dT%H:%M:%SZ) VCS_REF=\$$(git rev-parse --short HEAD 2>/dev/null || echo local) $(COMPOSE) $(COMPOSE_FLAGS) build --pull $(SERVICE)"

docker-up: docker-env-check docker-sync-mods
	@echo -e "$(BLUE)========================================================================$(RESET)"
	@echo -e "$(GREEN)  docker-up · mc-server (sync mods + build + up)$(RESET)"
	@echo -e "$(BLUE)========================================================================$(RESET)"
	$(RUN_LINUX) bash $(APP_DIR)/scripts/bash/docker-compose-up.sh

docker-rebuild: docker-env-check docker-sync-mods
	@echo -e "$(BLUE)========================================================================$(RESET)"
	@echo -e "$(GREEN)  docker-rebuild · mc-server (no-cache + recreate)$(RESET)"
	@echo -e "$(BLUE)========================================================================$(RESET)"
	$(RUN_LINUX) bash -lc "DOCKER_REBUILD=1 bash $(APP_DIR)/scripts/bash/docker-compose-up.sh"

docker-down: docker-env-check
	@echo -e "$(BLUE)========================================================================$(RESET)"
	@echo -e "$(GREEN)  docker-down · parando stack (bind mounts preservados)$(RESET)"
	@echo -e "$(BLUE)========================================================================$(RESET)"
	$(RUN_LINUX) $(COMPOSE) $(COMPOSE_FLAGS) down --remove-orphans

docker-restart: docker-env-check
	$(RUN_LINUX) $(COMPOSE) $(COMPOSE_FLAGS) restart $(SERVICE)

docker-ps: docker-env-check
	$(RUN_LINUX) $(COMPOSE) $(COMPOSE_FLAGS) ps

docker-logs: docker-env-check
	$(RUN_LINUX) $(COMPOSE) $(COMPOSE_FLAGS) logs --tail=$(DOCKER_LOGS_TAIL) $(if $(F),-f,) $(SERVICE)

docker-sh: docker-env-check
	$(RUN_LINUX) docker exec -it $(CONTAINER) /bin/bash || docker exec -it $(CONTAINER) /bin/sh

docker-smoke: docker-env-check
	$(RUN_LINUX) bash $(APP_DIR)/scripts/bash/test-docker.sh

docker-test: docker-smoke

docker-clean: docker-env-check
	@echo -e "$(RED)  docker-clean · remove containers, redes e volumes do projeto (mundo em app/runtime/world permanece)$(RESET)"
	$(RUN_LINUX) bash -lc "$(COMPOSE) $(COMPOSE_FLAGS) down --remove-orphans -v"

# ------------------------------------------------------------------------------
# Azure AKS
# ------------------------------------------------------------------------------

k8s-deploy:
	$(RUN_LINUX) bash $(APP_DIR)/scripts/bash/deploy-aks.sh

k8s-apply:
	$(RUN_LINUX) bash -lc 'set -euo pipefail; \
		if [[ -z "$${IMAGE_DIGEST:-}" ]]; then \
			echo "[ERRO] Defina IMAGE_DIGEST=sha256:... (equivale a make k8s-deploy)"; \
			exit 1; \
		fi; \
		bash app/scripts/bash/deploy-aks.sh'

k8s-annotate:
	$(RUN_LINUX) bash $(APP_DIR)/scripts/bash/atualizar-annotations-k8s.sh

k8s-test:
	$(RUN_LINUX) bash $(APP_DIR)/scripts/bash/test-aks.sh
