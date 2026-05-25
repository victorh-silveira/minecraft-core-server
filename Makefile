REPO_ROOT := $(CURDIR)
COMPOSE_FILE := infra/docker/docker-compose.yml
ENV_FILE := infra/docker/.env
COMPOSE := docker compose -f $(COMPOSE_FILE)
COMPOSE_FLAGS := --env-file $(ENV_FILE)
SERVICE := mc-server
CONTAINER := minecraft_core_server
TF_LIVE := infra/terraform/live/prod

RUN_LINUX := bash app/scripts/bash/run-in-linux-env.sh
CI_INFRA := $(RUN_LINUX) bash app/scripts/bash/ci-infra-local.sh
TERRAFORM_VERSION := 1.15.4

.PHONY: help docker-help ci-fmt ci-fmt-code ci-fmt-infra ci-lint ci-lint-infra ci-validate ci-validate-infra ci-infra ci-pre-push ci-test ci-validate terraform-fmt terraform-validate terraform-plan docker-env-check docker-sync-mods docker-build docker-pull docker-up docker-build-up docker-down docker-restart docker-logs docker-sh docker-clean docker-test docker-nuke k8s-apply k8s-annotate k8s-test pre-commit-install

help:
	@echo "Comandos Minecraft Server"
	@echo ""
	@echo "  CI local (Linux/WSL; no Windows use run-in-linux-env):"
	@echo "    make ci-fmt               Auto-format (Terraform + Python)"
	@echo "    make ci-lint              Lint completo (pre-commit)"
	@echo "    make ci-validate-infra    TFLint + tfsec + terraform validate"
	@echo "    make ci-infra             fmt + lint-infra + validate-infra"
	@echo "    make ci-pre-push          fmt + lint-infra + validate-infra (antes do push)"
	@echo "    make ci-pre-push-full     ci-pre-push + pre-commit completo"
	@echo "    make ci-test              Pytest + cobertura 100%%"
	@echo "    make ci-validate          Testes + validacoes (espelho CI)"
	@echo ""
	@echo "  Terraform (WSL):"
	@echo "    make terraform-fmt        Formata infra/terraform/ (Terraform $(TERRAFORM_VERSION))"
	@echo "    make terraform-validate   validate live/prod"
	@echo "    make terraform-plan       plan live/prod (requer Azure login)"
	@echo ""
	@echo "  Docker (WSL):"
	@echo "    make docker-build-up      Sync mods, build e sobe o servidor"
	@echo "    make docker-up            Sobe o servidor (build + recreate)"
	@echo "    make docker-down          Para e remove containers/rede"
	@echo "    make docker-restart       Reinicia o servico"
	@echo "    make docker-sync-mods     Baixa mods do mods-manifest.json"
	@echo "    make docker-logs          Logs em tempo real"
	@echo "    make docker-sh            Shell no container"
	@echo "    make docker-clean         Remove containers e imagens locais"
	@echo "    make docker-test          Valida Docker local"
	@echo "    make docker-nuke          Limpa todo Docker no WSL (confirmacao s/N)"
	@echo ""
	@echo "  Kubernetes (WSL):"
	@echo "    make k8s-apply            Aplica overlay prod no AKS"
	@echo "    make k8s-annotate         Atualiza annotations de conectividade e saude"
	@echo "    make k8s-test             Valida deploy AKS"
	@echo ""
	@echo "    make pre-commit-install   Instala hooks (.pre-commit-config.yaml)"

docker-help: help

ci-fmt: ci-fmt-infra ci-fmt-code

ci-fmt-infra:
	$(CI_INFRA) fmt

ci-fmt-code:
	$(RUN_LINUX) bash -lc "cd app && python -m ruff format --config pyproject.toml src/infrastructure/mods tests"
	$(RUN_LINUX) bash -lc "cd app && python -m ruff check --fix --config pyproject.toml src/infrastructure/mods tests"

ci-lint:
	$(RUN_LINUX) pre-commit run --all-files

ci-lint-infra:
	$(CI_INFRA) lint

ci-validate-infra:
	$(CI_INFRA) validate

ci-infra: ci-fmt-infra ci-lint-infra ci-validate-infra

ci-pre-push:
	$(RUN_LINUX) bash app/scripts/bash/ci-pre-push.sh

ci-pre-push-full: ci-pre-push ci-lint

ci-test:
	$(RUN_LINUX) bash -lc "cd app && python scripts/python/clean_workspace.py --stage test --coverage-fail-under 100"

ci-validate: ci-test
	$(RUN_LINUX) bash -lc "cd app && python scripts/python/clean_workspace.py --stage security"
	$(RUN_LINUX) bash app/scripts/bash/test-docker.sh

terraform-fmt: ci-fmt-infra

terraform-validate: ci-validate-infra

terraform-plan:
	@test -f $(TF_LIVE)/terraform.tfvars || (echo "Crie $(TF_LIVE)/terraform.tfvars a partir do .example" && exit 1)
	$(RUN_LINUX) bash -lc "cd $(TF_LIVE) && terraform init -input=false && terraform plan -input=false"

docker-env-check:
	@test -f $(ENV_FILE) || (echo "Arquivo $(ENV_FILE) nao encontrado. Copie infra/docker/.env.example para $(ENV_FILE)" && exit 1)

docker-sync-mods:
	$(RUN_LINUX) bash -lc "cd app && python -m infrastructure.mods"

docker-pull: docker-env-check
	$(RUN_LINUX) $(COMPOSE) $(COMPOSE_FLAGS) pull --ignore-pull-failures $(SERVICE)

docker-build: docker-env-check docker-pull
	$(RUN_LINUX) bash -lc "BUILD_DATE=\$$(date -u +%Y-%m-%dT%H:%M:%SZ) VCS_REF=\$$(git rev-parse --short HEAD 2>/dev/null || echo local) $(COMPOSE) $(COMPOSE_FLAGS) build --no-cache --pull $(SERVICE)"

docker-up: docker-env-check docker-sync-mods
	$(RUN_LINUX) $(COMPOSE) $(COMPOSE_FLAGS) up -d --build --force-recreate --renew-anon-volumes $(SERVICE)

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
	$(RUN_LINUX) bash -lc "$(COMPOSE) $(COMPOSE_FLAGS) down --remove-orphans --rmi local -v; docker rm -f $(CONTAINER) 2>/dev/null || true; docker rmi -f minecraft-core-server:latest 2>/dev/null || true"

docker-test: docker-env-check
	$(RUN_LINUX) bash app/scripts/bash/test-docker.sh

docker-nuke:
	$(RUN_LINUX) bash app/scripts/bash/docker-nuke.sh

k8s-apply:
	$(RUN_LINUX) bash -lc "kubectl apply -k infra/kubernetes/overlays/prod"
	$(RUN_LINUX) bash app/scripts/bash/atualizar-annotations-k8s.sh || true

k8s-annotate:
	$(RUN_LINUX) bash app/scripts/bash/atualizar-annotations-k8s.sh

k8s-test:
	$(RUN_LINUX) bash app/scripts/bash/test-aks.sh

pre-commit-install:
	$(RUN_LINUX) bash -lc "pre-commit install && pre-commit install --hook-type commit-msg"

.DEFAULT_GOAL := help
