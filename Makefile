REPO_ROOT := $(CURDIR)
COMPOSE_FILE := infra/docker/docker-compose.yml
ENV_FILE := infra/docker/.env
COMPOSE := docker compose -f $(COMPOSE_FILE)
COMPOSE_FLAGS := --env-file $(ENV_FILE)
SERVICE := mc-server
CONTAINER := minecraft_core_server
TF_LIVE := infra/terraform/live/prod

RUN_LINUX := bash app/scripts/bash/run-in-linux-env.sh
DEV_ENV := $(RUN_LINUX) bash app/scripts/bash/run-in-dev-env.sh
CI_INFRA := $(RUN_LINUX) bash app/scripts/bash/ci-infra-local.sh

.PHONY: help dev-deps ci-fmt ci-lint ci-validate-infra ci-infra ci-pre-push ci-test ci-validate terraform-plan docker-env-check docker-sync-mods docker-build docker-up docker-build-up docker-down docker-restart docker-logs docker-sh docker-clean docker-test docker-nuke k8s-deploy k8s-apply k8s-annotate k8s-test pre-commit-install clean

help:
	@echo "Minecraft Server - comandos essenciais"
	@echo ""
	@echo "  Setup (WSL, primeira vez):"
	@echo "    make dev-deps            Cria .venv e instala dependencias Python"
	@echo ""
	@echo "  CI (WSL):"
	@echo "    make ci-fmt              Terraform fmt + Ruff format"
	@echo "    make ci-lint             pre-commit em tudo"
	@echo "    make ci-pre-push         fmt + validate infra + lint Python"
	@echo "    make ci-test             pytest cobertura 100%%"
	@echo "    make ci-validate         testes + seguranca + docker-test"
	@echo "    make terraform-plan      plan live/prod"
	@echo ""
	@echo "  Docker (WSL):"
	@echo "    make docker-build-up     sync mods, build e sobe"
	@echo "    make docker-down         para containers"
	@echo "    make docker-logs         logs do servidor"
	@echo "    make docker-test         valida container local"
	@echo ""
	@echo "  Azure AKS (WSL + kubectl):"
	@echo "    make k8s-deploy          deploy manual (IMAGE_TAG, RCON_PASSWORD, MINECRAFT_WHITELIST)"
	@echo "    make k8s-apply           kubectl apply overlay prod"
	@echo "    make k8s-annotate        atualiza annotations de conectividade"
	@echo "    make k8s-test            diagnostico pos-deploy"
	@echo ""
	@echo "    make pre-commit-install  hooks git"
	@echo "    make clean               remove caches Python, .tools e lixo local"

dev-deps:
	$(DEV_ENV) python -c "import ruff, pytest, pre_commit; print('Dependencias Python OK')"

ci-fmt: dev-deps
	$(CI_INFRA) fmt
	$(DEV_ENV) python -m ruff format --config app/pyproject.toml app/src/infrastructure/mods app/tests

ci-lint: dev-deps
	$(DEV_ENV) pre-commit run --all-files

ci-validate-infra:
	$(CI_INFRA) validate

ci-infra: ci-fmt ci-validate-infra
	$(CI_INFRA) lint

ci-pre-push: ci-fmt ci-validate-infra
	$(CI_INFRA) lint
	$(DEV_ENV) python -m ruff check --fix --config app/pyproject.toml app/src/infrastructure/mods app/tests
	$(DEV_ENV) bash -lc "cd app && python scripts/python/clean_workspace.py --stage lint"

ci-test: dev-deps
	$(DEV_ENV) bash -lc "cd app && python scripts/python/clean_workspace.py --stage test --coverage-fail-under 100"

ci-validate: ci-test
	$(DEV_ENV) python app/scripts/python/clean_workspace.py --stage security
	$(RUN_LINUX) bash app/scripts/bash/test-docker.sh

terraform-plan:
	@test -f $(TF_LIVE)/terraform.tfvars || (echo "Crie $(TF_LIVE)/terraform.tfvars a partir do .example" && exit 1)
	$(RUN_LINUX) bash -lc "cd $(TF_LIVE) && terraform init -input=false && terraform plan -input=false"

docker-env-check:
	@test -f $(ENV_FILE) || (echo "Copie infra/docker/.env.example para $(ENV_FILE)" && exit 1)

docker-sync-mods: dev-deps
	$(DEV_ENV) bash -lc "cd app && python -m infrastructure.mods"

docker-build: docker-env-check
	$(RUN_LINUX) bash -lc "BUILD_DATE=\$$(date -u +%Y-%m-%dT%H:%M:%SZ) VCS_REF=\$$(git rev-parse --short HEAD 2>/dev/null || echo local) $(COMPOSE) $(COMPOSE_FLAGS) build --pull $(SERVICE)"

docker-up: docker-env-check docker-sync-mods
	$(RUN_LINUX) $(COMPOSE) $(COMPOSE_FLAGS) up -d --build --force-recreate $(SERVICE)

docker-build-up: docker-build docker-up

docker-down: docker-env-check
	$(RUN_LINUX) $(COMPOSE) $(COMPOSE_FLAGS) down --remove-orphans

docker-restart: docker-env-check
	$(RUN_LINUX) $(COMPOSE) $(COMPOSE_FLAGS) restart $(SERVICE)

docker-logs: docker-env-check
	$(RUN_LINUX) $(COMPOSE) $(COMPOSE_FLAGS) logs -f $(SERVICE)

docker-sh: docker-env-check
	$(RUN_LINUX) docker exec -it $(CONTAINER) /bin/bash || docker exec -it $(CONTAINER) /bin/sh

docker-clean: docker-env-check
	$(RUN_LINUX) bash -lc "$(COMPOSE) $(COMPOSE_FLAGS) down --remove-orphans --rmi local -v"

docker-test: docker-env-check
	$(RUN_LINUX) bash app/scripts/bash/test-docker.sh

docker-nuke:
	$(RUN_LINUX) bash app/scripts/bash/docker-nuke.sh

k8s-deploy:
	$(RUN_LINUX) bash app/scripts/bash/deploy-aks.sh

k8s-apply:
	$(RUN_LINUX) bash -lc "kubectl apply -k infra/kubernetes/overlays/prod"

k8s-annotate:
	$(RUN_LINUX) bash app/scripts/bash/atualizar-annotations-k8s.sh

k8s-test:
	$(RUN_LINUX) bash app/scripts/bash/test-aks.sh

pre-commit-install: dev-deps
	$(DEV_ENV) pre-commit install
	$(DEV_ENV) pre-commit install --hook-type commit-msg

clean:
	$(DEV_ENV) python app/scripts/python/clean_workspace.py --stage clean

.DEFAULT_GOAL := help
