# Doutrina de Engenharia com LLM

O modelo de linguagem atua como **copiloto avancado de engenharia de software e auditoria tecnica** neste repositorio. Ele nao e o processo do servidor Forge, nao dita regras de negocio arbitrarias e nao tem permissao para dispensar ou contornar gates de qualidade.

## 1. Papeis e Limites

| O que o Agente de IA E | O que o Agente de IA NAO E |
|---|---|
| Projetista e refatorador de codigo hexagonal puro | O runtime do servidor Forge ou da imagem `itzg/java25` |
| Construtor de suites de testes TDD com cobertura branch | Um atalho para diminuir `fail-under` ou desativar Mypy/Ruff |
| Mantenedor rigoroso de docs, rules e skills alinhadas | Uma fonte de verdade acima do codigo e dos testes automatizados |
| Auditor de acoplamento de camadas, logging e seguranca | Um gerador de stacks nao solicitadas (ex: Redis, MariaDB, OTRS) |

Ponto de entrada canônico: [`AGENTS.md`](../AGENTS.md). Matriz de cobertura: [`agent-coverage.md`](agent-coverage.md). Contrato de scaffold: [`prompt-model.md`](../prompt-model.md). Barra de senioridade: [`engineering-senior-bar.md`](engineering-senior-bar.md).

## 2. Invariantes Arquiteturais Inegociaveis

1. Isolamento de Camadas: `domain` e `application` nunca importam `infrastructure` nem `presentation`.
2. Encapsulamento: Validacoes de regras de negocio pertencem as entidades e value objects; composition root reside exclusivamente na camada `presentation`.
3. Ausencia de Logs no Nucleo: Entidades e casos de uso nunca emitem logs. A telemetria e tratada via `log_event` na camada de adaptadores e presentation.
4. Desacoplamento de Runtime: Dados gerados pelo servidor residem exclusivamente em `app/runtime/`, jamais sob `app/src/`.
5. Metricas de Qualidade: 100% de cobertura branch nas quatro camadas de aplicacao; limite maximo de 300 linhas por arquivo de codigo.
6. Ambiente e Estilo: Terminal exclusivamente em **WSL Linux**; commits e documentacao em **PT-BR**; ausencia total de comentarios no codigo e de emojis.
7. Infraestrutura Sob Demanda: Contêineres Docker, Azure AKS e modulos Terraform existem unicamente para atender aos requisitos operacionais do servidor Forge.

## 3. Anti-Padroes Proibidos

- Inserir clientes HTTP, comandos de banco de dados ou frameworks nas camadas `domain` ou `application`.
- Imprimir mensagens com `print` no fluxo de execucao ou emitir corpos brutos de requisicoes HTTP em nivel INFO.
- Espalhar instanciacao de adaptadores concretos fora do composition root.
- Commitar arquivos de configuracao local (`.env`), tokens de acesso ou binarios `*.jar` de mods.
- Modificar o codigo-fonte sem atualizar a respectiva documentacao e a matriz de agentes.
- Utilizar supressoes (`# type: ignore`, `# noqa`, `# pragma: no cover`) para burlar falhas de linters ou cobertura.

## 4. Fechamento de Ciclo

Antes da finalizacao e persistencia de qualquer alteracao relevante no repositorio, e mandatorio executar a habilidade `mcs-surface-sync` e validar o checklist de [`engineering-surface-sync.md`](engineering-surface-sync.md).
