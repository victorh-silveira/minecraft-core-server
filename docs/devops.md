# DevOps

## Dockerfile

Local: [`Dockerfile`](../Dockerfile)

| Pratica | Implementacao |
|---------|---------------|
| BuildKit | `# syntax=docker/dockerfile:1.7` |
| Labels OCI | title, version, revision, vendor, base image |
| Non-root | `USER minecraft` apos setup |
| COPY seguro | `--chown=minecraft:minecraft` |
| Healthcheck | `mc-health` (start-period 180s) |
| Volumes declarados | world, mods, plugins, logs |
| EXPOSE | 25565/tcp, 25575/tcp |

Templates em `/templates/` servem como fallback na imagem; em runtime os **bind mounts** de `src/` prevalecem.

---

## Docker Compose

Local: [`docker-compose.yml`](../docker-compose.yml)

| Recurso | Detalhe |
|---------|---------|
| Projeto | `name: minecraft-server` |
| Rede | `minecraft-core-network` (bridge) |
| Logging | json-file, 10m x 5 arquivos, compress |
| Seguranca | `no-new-privileges:true` |
| Recursos | `mem_limit`, `pids_limit` |
| Graceful stop | `stop_grace_period: 60s` |
| Init | `init: true` (reaping de processos zombie) |
| Healthcheck | Compose + Dockerfile |

### Bind mounts long-form

Volumes com `create_host_path: true` e `read_only: true` em configs.

---

## `.dockerignore`

Categorias alinhadas ao `.gitignore`:

- Git, segredos, caches Python, Node, IDEs
- Docs, tests, scripts (nao necessarios no build context)
- Dados persistentes e JARs

Contexto de build minimo: configs + manifesto.

---

## Makefile

Prefixo obrigatorio: **`docker-*`**

| Comando | Descricao |
|---------|-----------|
| `docker-help` | Lista comandos (padrao) |
| `docker-build-up` | Sync mods, build e sobe o servidor |
| `docker-up` | Sobe com build e recreate |
| `docker-down` | Para e remove containers/rede |
| `docker-restart` | Reinicia o servico |
| `docker-sync-mods` | Roda `sync_mods.py` |
| `docker-logs` | Logs em tempo real |
| `docker-sh` | Shell no container |
| `docker-clean` | Remove containers e imagens locais |

---

## Pre-commit

Instalacao:

```powershell
pip install -r requirements-dev.txt
pre-commit install
pre-commit install --hook-type commit-msg
```

Execucao manual:

```powershell
pre-commit run --all-files
```

Hooks usam `always_run: true` em lint/test/security para nao serem skipped sem arquivos Python rastreados no Git.

---

## Quality gate (`clean_workspace.py`)

| Stage | Ferramentas |
|-------|-------------|
| lint | Ruff check/format, Vulture, Pylint duplicate-code, limite 300 linhas |
| test | pytest + coverage 100% em `scripts/python/sync_mods.py` |
| security | Bandit (scripts/python/), pip-audit (requirements.txt) |
| clean | Remove `__pycache__`, `.pytest_cache`, `.ruff_cache`, etc. |

---

## Semantic Release

Config: [`tools/releaserc.mjs`](../tools/releaserc.mjs)

```bash
npx semantic-release --extends ./tools/releaserc.mjs
```

Gera `docs/CHANGELOG.md` e tagueia versoes a partir de Conventional Commits.

Branches elegiveis: `main`.

---

## CI/CD (nao implementado)

Pipeline minimo sugerido (GitHub Actions):

```yaml
- pip install -r requirements-dev.txt
- python scripts/python/sync_mods.py
- python scripts/python/clean_workspace.py --stage lint
- python scripts/python/clean_workspace.py --stage test
- python scripts/python/clean_workspace.py --stage security
- docker compose --env-file .env.example config
```

Ver [roadmap.md](roadmap.md).

---

## Scorecard DevOps

| Item | Status |
|------|--------|
| Dockerfile production-ready | OK |
| Compose hardened | OK |
| Makefile | OK |
| Pre-commit | OK |
| Testes automatizados | OK |
| CI/CD | Pendente |
| Pin de versao base (nao `latest`) | Pendente |
| Docker Secrets | Pendente |
