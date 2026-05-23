# DRY, SOLID e qualidade de codigo

## DRY (Don't Repeat Yourself)

### Bem aplicado

| Area | Mecanismo |
|------|-----------|
| Parametros de infra | `.env` + `.env.example` |
| Compose | Anchors YAML (`x-logging-default`, `x-mc-server-common`) |
| Comandos Docker | Makefile com prefixo `docker-*` |
| Dependencias de mods | `mods-manifest.json` (sem JARs no Git) |
| Quality gates | `clean_workspace.py` centraliza lint/test/security |

### Duplicidades conhecidas

#### 1. Configuracao do jogo em dois lugares

Variaveis no Compose (`ONLINE_MODE`, `DIFFICULTY`, `MAX_PLAYERS`) **e** `server.properties` montado separadamente.

A imagem [itzg/minecraft-server](https://hub.docker.com/r/itzg/minecraft-server) pode gerar ou sobrescrever `server.properties` a partir de env vars.

**Recomendacao:** escolher uma fonte primaria (ver [configuration.md](configuration.md)).

#### 2. ENV duplicado Dockerfile vs Compose

`ENABLE_RCON`, `USE_AIKAR_FLAGS`, `UID`, `GID` aparecem em ambos.

**Recomendacao:** manter defaults no Dockerfile; Compose sobrescreve apenas o necessario via `.env`.

#### 3. `.env` desatualizado

Garantir que o `.env` local inclua todas as chaves de `.env.example` (incluindo secao Docker Build).

### Scorecard DRY

| Area | Nota |
|------|------|
| Infra parametrizada | 9/10 |
| Config do jogo | 6/10 |
| Documentacao | 8/10 (apos criacao de docs/) |

---

## SOLID (analise de `app/src/infrastructure/mods/`)

### Single Responsibility (S)

Funcoes pequenas e focadas: `sha256_file`, `jar_path`, `resolve_modrinth`, `download_jar`.

`sync_mod` concentra validacao, I/O e orquestracao — aceitavel no tamanho atual (~170 linhas).

### Open/Closed (O)

`resolve_download` estende comportamento por `source` (`modrinth`, `curseforge`) sem alterar `main()`.

### Liskov Substitution (L)

Nao aplicavel — sem hierarquia de classes.

### Interface Segregation (I)

Fraco — nao ha interfaces (`ModProvider`, `ManifestRepository`). Acoplamento direto a `requests` e paths globais.

### Dependency Inversion (D)

Fraco — paths hardcoded (`MANIFEST_PATH`, `MODS_DIR`). Testes usam `monkeypatch` para contornar.

### Evolucao SOLID sugerida

```text
src/infrastructure/mods/
├── providers/
│   ├── modrinth.py
│   └── curseforge.py
├── manifest.py
└── sync_service.py
```

Com injecao de paths e HTTP client nos testes, sem monkeypatch global.

### Scorecard SOLID

| Principio | Nota | Comentario |
|-----------|------|------------|
| S | 7/10 | Funcoes coesas |
| O | 8/10 | Extensivel por source |
| L | N/A | — |
| I | 4/10 | Sem abstracoes |
| D | 4/10 | Acoplamento a requests/paths |

**Conclusao:** pragmatico e **100% testado**; SOLID pleno e opcional neste estagio.

---

## Testes e cobertura

- `tests/unit/infrastructure/mods/test_sync.py` — 22 testes
- Cobertura minima **100%** em `app/src/infrastructure/mods/` (via `pyproject.toml`)
- `app/scripts/python/clean_workspace.py` omitido da cobertura (ferramenta de dev)

---

## Pre-commit e commits

Hooks locais (`.pre-commit-config.yaml`, padrao `Area | Acao`):

| Nome | Funcao |
|------|--------|
| Codigo \| Lint Python (Ruff) | Lint com correcao automatica |
| Codigo \| Formatar Python (Ruff) | Formatacao |
| Codigo \| Validar JSON (manifesto de mods) | Sintaxe do `mods-manifest.json` |
| Infra \| Formatar Terraform | `terraform fmt -check -recursive` em `infra/terraform/` |
| Infra \| Validar Terraform | `terraform validate` em live/prod |
| Infra \| Validar sintaxe YAML | Kubernetes e workflows GitHub |
| Docker \| Lint Dockerfile | Hadolint |
| Arquivo \| Garantir newline no fim | EOF |
| Arquivo \| Remover espacos no fim da linha | Trailing whitespace |
| Commit \| Validar Conventional Commits | Hook `commit-msg` |

No CI (`clean_workspace.py`): Vulture, Pylint, pytest, Bandit, pip-audit, tflint, tfsec, kubeconform.

Formato de commit: `tipo(escopo): assunto` com corpo obrigatorio.

Escopos validos: `docker`, `mods`, `domain`, `infra`, `scripts`, `config`, etc. (ver `tools/commitlint.config.mjs`).
