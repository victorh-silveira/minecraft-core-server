# Contrato de Engenharia e Modelo de Scaffold

Contrato reutilizavel e agnostico de engenharia derivado da arquitetura deste repositorio. Define o modelo canônico para criacao ou refatoracao de qualquer projeto orientado a DDD, Arquitetura Hexagonal, TDD rigoroso, barra de qualidade maxima e harness de agentes.

O dominio Minecraft Forge deste repositorio serve como referencia de implementacao prática; os principios definidos neste contrato sao universais e aplicaveis a qualquer dominio de negocio.

## 1. Missao do Engenheiro de Software

Ao projetar, estender ou adaptar um repositorio sob este modelo, voce deve:

- Isolar o nucleo de negocio de qualquer acoplamento tecnologico externo
- Construir a solucao respeitando o fluxo TDD camada por camada
- Garantir 100% de cobertura branch nas camadas de aplicacao
- Manter documentacao tecnica, regras de agentes, hooks e Makefiles perfeitamente sincronizados com o codigo-fonte
- Nao adicionar frameworks, bibliotecas ou servicos externos sem demanda explicita do dominio

## 2. Invariantes Arquiteturais (Agnosticos de Linguagem)

### Segregacao Estrita de Camadas (Hexagonal / DDD)

| Camada | Responsabilidade | Dependencias Permitidas |
|---|---|---|
| `domain` | Entidades, Value Objects, Domain Services, validacao de invariantes de negocio | Nenhuma dependencia externa ao dominio |
| `application` | Casos de uso (Use Cases) e contratos de saida/entrada (Ports / Interfaces) | Apenas `domain` |
| `infrastructure` | Adaptadores concretos (HTTP, Banco de Dados, Arquivos), configuracao e logging | `application` e `domain` |
| `presentation` | Entrypoints (CLI, API, UI, Workers) e Composition Root (injecao de dependencias) | `application`, `domain` e `infrastructure` |

### Regras Mandatorias de Dependencia

1. `domain` e `application` nunca importam `infrastructure` nem `presentation`.
2. Ports sao contratos puros (Protocols/Interfaces). Adapters implementam esses contratos na camada `infrastructure`.
3. Validacoes e regras de negocio pertencem exclusivamente ao `domain`.
4. Domain e use cases nunca emitem logs ou realizam I/O direto. O logging semantico reside nos adapters e na presentation.
5. O Composition Root (leitura de configuracoes e instanciacao dos adapters e use cases) localiza-se unicamente na camada `presentation`.

### Diretrizes de Qualidade e Limpeza

- Codigo limpo: Sem comentarios no codigo-fonte. O design e a tipagem estrita devem expressar a intencao.
- Padrao de idioma: Documentacao tecnica, mensagens de erro e commits exclusivamente em **PT-BR**.
- Ausencia de emojis: Proibido o uso de emojis em codigo, logs, commits ou documentacao tecnica.
- Limite de complexidade: Nenhum arquivo de aplicacao deve exceder **300** linhas de codigo.
- Cobertura de testes: Meta inegociavel de **100% branch coverage** nas camadas `domain`, `application`, `infrastructure` e `presentation`.
- Seguranca: Configuracao via `.env` na raiz apoiada por `.env.example`. Proibido versionar credenciais ou tokens.

## 3. Topologia Padrao de Diretorios

```text
.
├── .agents/                      # Harness canonico de IA
│   ├── rules/                    # Regras de governanca (.mdc)
│   ├── skills/                   # Habilidades operacionais com SKILL.md
│   ├── agents/                   # Personas e subagentes seniores
│   └── mcp.json                  # Configuracao canonica de ferramentas MCP
├── .cursor/                      # Ponte de retrocompatibilidade para Cursor IDE
├── app/
│   ├── src/
│   │   ├── domain/               # Entidades e servicos de dominio puro
│   │   ├── application/          # Casos de uso e portas abstratas
│   │   ├── infrastructure/       # Adaptadores de rede, disco e configuracao
│   │   └── presentation/         # CLI, entrypoint e composition root
│   ├── runtime/                  # Dados volateis de execucao desacoplados do codigo
│   ├── tests/
│   │   ├── unit/                 # Testes unitarios por camada com fakes
│   │   └── integration/          # Testes de adaptadores de I/O
│   ├── scripts/
│   │   └── operations/           # Orquestrador de qualidade e gates
│   ├── pyproject.toml
│   ├── requirements.txt
│   └── requirements-dev.txt
├── docs/                         # Documentacao tecnica e matriz de cobertura 100%
├── infra/                        # Contêineres e definicoes de nuvem (Docker, AKS, Terraform)
├── linters/                      # Configuracoes de commitlint e hooks de git
├── Makefile                      # Comandos padronizados de DX e automacao
├── AGENTS.md                     # Ponto de entrada universal para LLMs
├── prompt-model.md               # Este contrato de engenharia
└── README.md                     # Portal do desenvolvedor
```

## 4. Engenharia de Testes (TDD por Camada)

1. `domain`: Testes unitarios puros validando entidades, invariantes e servicos sem nenhum mock.
2. `application`: Testes unitarios usando Fakes em memoria para os Ports, garantindo isolamento total de I/O externo.
3. `infrastructure`: Testes de integracao com transportes simulados (mocks de rede ou bancos em memoria) validando contratos.
4. `presentation`: Testes de ponta a ponta da CLI/API garantindo o wiring do composition root.

## 5. Portao de Qualidade e Linters

- Python: Ruff (lint e formatacao), Mypy (`strict = true`), Vulture (deteccao de codigo morto), Pylint (codigo duplicado), Bandit (analise estatica de seguranca), Pip-audit (vulnerabilidades em dependencias), Gitleaks (deteccao de segredos) e Pytest com cobertura branch minima de 100%.
- Outras linguagens: Ferramentas equivalentes que garantam analise estatica estrita, zero codigo morto e 100% de cobertura.
- Orquestrador: Script central (`clean_workspace.py`) chamado pelos alvos do `Makefile` (`make app-lint`, `make app-validate`, `make app-test`, `make app-security`, `make app-build`).

## 6. Prompt para Bootstrap de Novos Projetos

Copie o modelo abaixo para instruir um agente a construir ou migrar um projeto aderente a este contrato:

```text
Voce e um engenheiro de software senior. Implemente o projeto abaixo seguindo integralmente o Contrato de Engenharia de Referencia (DDD + Arquitetura Hexagonal + TDD + Harness de Agentes .agents/).

PROJETO:
- Nome: <<<NOME_DO_PROJETO>>>
- Dominio e Objetivo: <<<DESCRICAO_DO_DOMINIO>>>
- Linguagem e Runtime: <<<LINGUAGEM>>>
- Ponto de Entrada: <<<CLI/API/WORKER>>>
- Integracoes Externas: <<<SERVICOS_EXTERNOS>>>

DIRETRIZES OBRIGATORIAS:
1. Camadas: domain (puro), application (use cases + ports), infrastructure (adapters), presentation (composition root).
2. Proibicao absoluta de imports de infraestrutura ou presentation em domain/application.
3. Sem comentarios no codigo; documentacao em PT-BR; zero emojis; commits no padrao Conventional Commits.
4. TDD camada por camada com cobertura branch de 100%.
5. Harness de agentes estruturado em .agents/ com rules, skills, subagentes e mcp.json.
6. Limite maximo de 300 linhas por arquivo.
7. Makefile padronizado (app-install, app-lint, app-validate, app-test, app-security, app-build).
```

Referencias locais: [`AGENTS.md`](AGENTS.md), [`docs/arquitetura.md`](docs/arquitetura.md), [`docs/structure.md`](docs/structure.md), [`docs/agent-coverage.md`](docs/agent-coverage.md).
