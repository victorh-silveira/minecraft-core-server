# Roadmap

Gaps e prioridades apos a stack Azure AKS + backup + annotations. O [CHANGELOG.md](CHANGELOG.md) registra entregas por release.

## Scorecard atual

| Pilar | Nota | Resumo |
|-------|------|--------|
| Clean Architecture | 8/10 | Pastas + `infrastructure.mods` em `src/` |
| DRY | 6/10 | Config jogo duplicada local |
| SOLID | 6/10 | Testado; DI limitada |
| DDD | 7/10 | Estrutural; mundo como agregado de dados |
| DevOps / IaC | 9/10 | CI/CD, TF, K8s, backup, annotations |
| Observabilidade | 5/10 | Probes + logs; sem metricas |

## Concluido

- [x] Estrutura `app/src/` e sync de mods
- [x] Docker Compose e Makefile
- [x] Pre-commit e CI completo
- [x] Terraform modules + live/prod (AKS, ACR, rede)
- [x] Kubernetes base + overlay prod
- [x] AKS Workload Identity + backup CronJob para blob
- [x] StorageClass Retain e K8s 1.31 pinado
- [x] CD GitOps (infra + app + pos-deploy)
- [x] Annotations `minecraft-server.io/*` (Azure, K8s, Minecraft, saude)
- [x] Documentacao alinhada a arquitetura atual

## Prioridade 1 — Configuracao unica (DRY local)

Unificar `ONLINE_MODE`, `DIFFICULTY`, `MAX_PLAYERS` entre `.env` e `server.properties`.

Ver [configuration.md](configuration.md).

## Prioridade 2 — Pin da imagem base Docker

Substituir tag flutuante de `itzg/minecraft-server` por tag ou digest fixo em `.env.example`.

## Prioridade 3 — SOLID / injecao de dependencias

Expandir `providers.py` e reduzir monkeypatch nos testes.

## Prioridade 4 — Segredos em Key Vault

Migrar `RCON_PASSWORD` e credenciais sensiveis para Azure Key Vault + CSI ou External Secrets.

## Prioridade 5 — Ambientes Compose

Profiles `dev` / `staging` ou override gitignored.

## Prioridade 6 — Observabilidade (custo)

Sidecar `prometheus-minecraft-exporter` ou agente leve; avaliar RAM no node `Standard_D2s_v6` unico.

## Prioridade 7 — Retencao de backups

Lifecycle policy no container `world-backups` (ex.: manter 7/30 dias).

## Prioridade 8 — Multi-node / HA

Segundo node ou pod disruption budget com minAvailable 1 quando escalar.

## Processo de mods

1. Branch `feature/atualizar-mods`
2. Editar manifesto + `make docker-sync-mods`
3. Testar local e AKS
4. Merge apos validacao in-game

CI pode exigir sync em branch futura.
