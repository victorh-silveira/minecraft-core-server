# Barra senior (Software + Cloud Ops)

Padrao de comportamento exigido de engenheiros e operadores seniores neste repositorio.
Complementa [`llm-engineering-doctrine.md`](llm-engineering-doctrine.md) e a matriz em [`agent-coverage.md`](agent-coverage.md).

Agentes: `.cursor/agents/mcs-senior-*.md`. Skills: `mcs-senior-software`, `mcs-senior-cloud-ops`, `mcs-senior-review`.

## Postura

- Preferir evidencia (gates, schemas, diffs, probes) a opiniao.
- Mudanca minima alinhada ao dominio Fabric; nao importar stacks alheias.
- Nao afrouxar QA; corrigir a causa.
- Separar papel **Software Engineer** (camadas Python, Dockerfile app) de **Cloud Ops** (Compose paridade, AKS, Terraform, CI/CD, observabilidade).

## Software Engineer — Python hexagonal

### DIP e camadas

| Camada | Pode | Nao pode |
|--------|------|----------|
| `domain` | Entidades/VO/services puros; validacao no construtor | HTTP, FS, env, logging, libs externas alem da stdlib |
| `application` | Use cases; ports (`Protocol`); orquestracao | `requests`/httpx, logs, DTOs de API externa |
| `infrastructure` | Adapters HTTP/FS/JSON; mapeamento DTO → dominio | Expor modelos Modrinth/CurseForge ao domain |
| `presentation` | Composition root; CLI; `log_event` | Logica de negocio; regras de hash/versao |

- Adaptadores convertem via DTO + mapper; o domain so ve tipos de dominio.
- Cliente HTTP atual: `requests` (`HttpClient`, `RequestsArtifactDownloader`). Migracao para `httpx`/asyncio so com TDD e surface sync.

### Python 3.13+

- Tipagem estrita (mypy `--strict`); sem `# type: ignore` sem justificativa documentada na review.
- I/O concorrente futuro: preferir `asyncio.TaskGroup` a `gather` solto (cancelamento e excecoes consistentes).
- Free-threaded (PEP 703): avaliar impacto de extensoes C antes de assumir paralelismo CPU; sync de mods e I/O-bound.

### Resiliencia do sync

- Resolucao deterministica; validacao de hash pos-download (SHA-256 de 64 hex no manifesto; cruzar com hash do provedor quando ambos existem).
- Em adapters: exponential backoff com jitter em HTTP 429/5xx; nao martelar upstream.
- Rate-limit (token/leaky bucket) so quando houver necessidade comprovada; estado em memoria primeiro; Redis so se multi-replica exigir.
- Nunca logar body JSON de API nem API keys; URLs com query → `?***`.

## Software Engineer — Docker

- Multi-stage quando houver build de wheels/compilacao; runtime so com o necessario.
- Ordem de COPY: lock/requirements antes do codigo-fonte (cache de camadas).
- PID 1: `tini`/`dumb-init` ou `STOPSIGNAL SIGTERM` explicito; sync nao deve corromper JAR a meio.
- Usuario nao-root com UID/GID fixos alinhados ao Compose/K8s.
- Hadolint bloqueante; sem `latest` em bases de producao.

## Cloud Ops — Compose / AKS / Terraform

### Compose (paridade)

- Healthchecks com `interval`, `timeout`, `retries`, `start_period` espelhando probes.
- Profiles (`debug`, `tools`) para ferramentas locais, nao no path de producao.

### Kubernetes (Kustomize)

- `startupProbe` para boot pesado; `readiness` desacoplado de `liveness`.
- Config via ConfigMap/Secret (env ou volume); sem secrets bake-in na imagem.
- Overlays `base` + `overlays/{dev,staging,prod}` com patches; sem duplicar manifests.
- PDB, LimitRange/ResourceQuota, NetworkPolicy (egress minimo) em prod.

### Terraform (`live/prod`)

- Modulos com blast-radius isolado (`network` / `aks`; state Blob separado).
- State em Azure Blob com lock, versionamento, soft delete, RBAC.
- Provider via OIDC (GitHub Actions); sem `ARM_CLIENT_SECRET` de longa duracao.
- AKS: Workload Identity para Key Vault futuro; imagens via GHCR; pool unico no Free tier (system/user separados so em SKU pago); Spot so para jobs nao criticos.

### Segredos

- Tokens CurseForge/Modrinth e similares: Key Vault + injecao em runtime; nunca no Git nem em logs.

## Cloud Ops — CI/CD e QA

- Matriz QA obrigatoria; `[skip-cd]` pula **somente** deploy/infra, nunca lint/test/security de branch protection.
- OIDC (`id-token: write`); imagens imutaveis por SHA curto; sem promover `latest` a prod.
- Ruff primeiro (fail fast); mypy strict; pytest `--cov-branch` 100%; Bandit; pip-audit; Hadolint; tflint/tfsec; kubeconform no `kustomize build`; Trivy bloqueia CRITICAL/HIGH com fix disponivel.
- Observabilidade alvo: OpenTelemetry nos adapters HTTP de mods + alertas 5xx/upstream; introduzir sem quebrar hexagonal (instrumentacao na infrastructure/presentation).

## Anti-padroes senior

- Modelos de API externa vazando para `domain`
- `asyncio.gather` sem escopo estruturado em codigo novo async
- Credencial estatica no workflow ou Terraform
- Probe unico fazendo as vezes de liveness+readiness
- Skip de QA via mensagem de commit
- Cache de JAR sem validacao de hash
- Introduzir OTEL/Redis/S3 sem necessidade do dominio e sem TDD

## Fechamento

Skill `mcs-surface-sync` + gates WSL apos mudanca material.
