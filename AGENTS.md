# AGENTS.md — Minecraft Core Server

Guia mestre e ponto de entrada para agentes de IA e copilotos de engenharia neste repositorio.

## 1. Ambiente e Diretrizes Gerais

- Idioma: Respostas, mensagens de commit e documentacao tecnica exclusivamente em **PT-BR**
- Terminal e execucao: **WSL Linux** obrigatorio (nunca CMD ou PowerShell nativo)
- Proibicao de emojis: Sem emojis em codigo-fonte, mensagens de log, commits ou documentacao tecnica
- Codigo limpo: Sem comentarios no codigo-fonte (o codigo deve ser autoexplicativo por nomes e tipagem estrita)
- Estrutura de agentes: Harness canonico e agnostico versionado em [`.agents/`](.agents/)

## 2. Universo Operacional do Projeto

- Servidor de jogo: Minecraft **Forge 26.3 / Forge 66.0.6** (imagem oficial `itzg/java25`), operando sem mods instalados por padrao
- Aplicacao Python: Sincronizador de JARs com arquitetura hexagonal estrita, consumindo manifesto em `app/runtime/mods/mods-manifest.json`
- Camadas da aplicacao: `app/src/{domain,application,infrastructure,presentation}`
- Segregacao de dados de jogo: `app/runtime/{world,configs,mods,plugins,logs,database}` (nunca versionar sob `app/src/`)
- Orquestracao de contêineres: Docker Compose para desenvolvimento local; Azure AKS com modulos Terraform para ambiente produtivo
- Entrypoints da aplicacao: `python run.py`, `make docker-sync-mods`
- Orquestrador de qualidade: `app/scripts/operations/clean_workspace.py` (`--area` e `--stage`)

## 3. Papel do Agente de IA

- O agente atua como copiloto avancado de engenharia de software, automacao de infraestrutura e auditoria tecnica
- O agente nao substitui os gates de qualidade automatizados, nao executa acoes destrutivas sem validacao e nao adultera contratos de camadas
- O agente deve sempre coletar evidencias objetivas (saidas de comandos, relatorios de testes, analises estaticas) antes de concluir qualquer alteracao

## 4. Proibicoes Globais Inegociaveis

- Nunca importar clientes HTTP, drivers de banco de dados ou frameworks externos nas camadas `domain` ou `application`
- Nunca emitir chamadas de log dentro de use cases ou entidades de dominio
- Nunca posicionar o composition root fora da camada `presentation`
- Nunca gravar dados de runtime do jogo sob `app/src/`
- Nunca permitir que arquivos Python em `app/src/**/*.py` ou `run.py` ultrapassem o limite de **300** linhas
- Nunca permitir cobertura branch de testes abaixo de **100%** nas camadas `domain`, `application`, `infrastructure` e `presentation`
- Nunca rebaixar `fail-under` ou desativar temporariamente analisadores (Ruff, Mypy, Vulture, Pylint, Bandit, Pip-audit, Trivy)
- Nunca commitar arquivos `.env`, credenciais, tokens de API ou arquivos binarios `*.jar` de mods
- Nunca utilizar mensagens de commit em idioma diferente de PT-BR ou com escopos fora do enum de commitlint

## 5. Roteamento de Contexto por Tarefa

| Tipo de Tarefa | Documentacao Primaria | Regra (.agents/rules/) | Habilidade (.agents/skills/) | Subagente Recomendado |
|---|---|---|---|---|
| Nova feature Python / Dominio | `docs/arquitetura.md` | `mcs-hexagonal.mdc`, `mcs-domain-pure.mdc` | `mcs-hexagonal-tdd` | `mcs-senior-software-engineer` |
| Sincronizacao de mods / Resolvers | `docs/configuration.md` | `mcs-mods-sync.mdc` | `mcs-mods-sync` | `mcs-senior-software-engineer` |
| Logging e telemetria | `docs/engineering-logging.md` | `mcs-logging.mdc` | `mcs-logging-audit` | `mcs-senior-software-engineer` |
| Docker / Runtime / Bind mounts | `docs/infra-docker.md` | `mcs-infra.mdc`, `mcs-runtime-data.mdc` | `mcs-infra-stack` | `mcs-senior-cloud-ops` |
| Azure AKS / Terraform / Cloud Ops | `docs/operations.md`, `docs/azure.md` | `mcs-senior-cloud.mdc`, `mcs-senior-cicd.mdc` | `mcs-senior-cloud-ops` | `mcs-senior-cloud-ops` |
| Revisao de codigo / Auditoria QA | `docs/engineering-senior-bar.md` | `mcs-senior-posture.mdc` | `mcs-senior-review` | `mcs-senior-qa-auditor` |
| Dependencias Python | `docs/engineering-python-deps.md` | `mcs-python-deps.mdc` | `mcs-python-deps` | `mcs-senior-software-engineer` |
| Limpeza e remocao de codigo morto | `docs/engineering-repo-hygiene.md` | `mcs-repo-hygiene.mdc` | `mcs-repo-hygiene` | `mcs-senior-software-engineer` |
| Fechamento e sincronizacao | `docs/engineering-surface-sync.md` | `mcs-surface-sync.mdc` | `mcs-surface-sync` | `mcs-senior-qa-auditor` |

## 6. Comandos e Portoes de Qualidade (Make)

| Comando | Escopo e Efeito |
|---|---|
| `make app-install` | Valida instalacao das dependencias no ambiente virtual WSL |
| `make app-lint` | Executa Ruff, Vulture, Pylint e verificacoes estruturais em modo crash-first |
| `make app-validate` | Executa Mypy strict em todas as fontes e valida schemas de infraestrutura |
| `make app-security` | Executa Bandit, Pip-audit, Gitleaks, Trivy e Tfsec |
| `make app-test` | Executa testes unitarios e de integracao exigindo 100% de cobertura branch |
| `make app-build` | Executa compilacao de bytecode Python para validacao de sintaxe |
| `make app-pre-commit-run` | Dispara toda a suite de verificacao em lote em todos os arquivos |

Entrada detalhada da matriz de cobertura: [`docs/agent-coverage.md`](docs/agent-coverage.md).
Contrato arquitetural: [`prompt-model.md`](prompt-model.md).
