# DRY, SOLID e qualidade

Convencoes de codigo, testes e gates de qualidade do monorepo.

## DRY

### Bem aplicado

| Area | Mecanismo |
|------|-----------|
| Parametros infra local | `infra/docker/.env` + `.env.example` |
| Compose | Anchors YAML reutilizaveis |
| Comandos | Makefile (`docker-*`, `k8s-*`, `ci-*`) |
| Mods | `mods-manifest.json` (sem JARs no Git) |
| Quality gate | `clean_workspace.py` |
| Metadados K8s | `commonAnnotations` + script de patch |

### Duplicidades conhecidas

**Config do jogo:** `.env` / StatefulSet env **e** `server.properties`. Ver [configuration.md](configuration.md).

**ENV Dockerfile vs Compose:** defaults na imagem; Compose sobrescreve via `.env`.

### Scorecard DRY

| Area | Nota |
|------|------|
| Infra parametrizada | 9/10 |
| Config jogo | 6/10 |
| Documentacao | 9/10 |

## SOLID (`app/src/infrastructure/mods/`)

| Principio | Nota | Comentario |
|-----------|------|------------|
| S | 7/10 | Funcoes focadas; `sync_mod` coeso |
| O | 8/10 | Novas sources via registro de resolvers |
| L | N/A | — |
| I | 5/10 | `ModResolver` Protocol |
| D | 5/10 | Testes com monkeypatch de paths |

Cobertura **100%** em `infrastructure.mods` (pytest + coverage).

## Testes

```bash
make ci-test
cd app && python -m pytest tests/unit/infrastructure/mods/test_sync.py -v
```

## Pre-commit e commits

Formato: `tipo(escopo): assunto` com corpo obrigatorio (`commitlint`).

Escopos: `docker`, `mods`, `infra`, `scripts`, `config`, `test`, etc. (`app/tools/commitlint.config.mjs`).

CI adiciona: Gitleaks, kubeconform, tflint, tfsec.

## IaC e K8s

- Terraform: descriptions em PT-BR em variables/outputs
- Kubernetes: labels `app.kubernetes.io/component` e annotations `minecraft-server.io/*`
- NSG e StorageClass com nomenclatura em portugues onde aplicavel

Ver [architecture.md](architecture.md) e [annotations.md](annotations.md).
