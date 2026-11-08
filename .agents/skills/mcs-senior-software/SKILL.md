---
name: mcs-senior-software
description: >-
  Aplica os padroes de Engenharia de Software Senior na implementacao de codigo Python
  (padrao hexagonal, inversao de dependencias, TDD rigoroso, tipagem estrita e resiliencia).
  Use when designing new modules, refactoring use cases, or implementing complex adapters.
---

# Habilidade: mcs-senior-software

Diretrizes avancadas de engenharia para implementacao de recursos em Python.

## Principios de Implementacao

1. Inversao de Dependencia e DIP:
   - Use cases dependem de abstracoes (`typing.Protocol`), nunca de implementacoes concretas.
   - Nenhuma classe de infraestrutura deve ser instanciada diretamente dentro do caso de uso.

2. Mapeamento de Dados e Isolamento:
   - Respostas de APIs externas (como Modrinth) devem ser tratadas em DTOs internos ou mappers dedicados (`modrinth_mapper.py`), isolando modelos de terceiros do dominio.
   - Entidades de dominio devem expor metodos de mutacao controlada ou ser totalmente imutaveis via `dataclass(frozen=True)`.

3. Resiliencia de I/O na Borda:
   - Adaptadores de rede devem implementar timeouts explicitos, backoff exponencial e tratamento robusto de conexoes caidas.
   - Erros de rede devem ser encapsulados em excecoes de aplicacao sem expor detalhes internos do cliente HTTP para as camadas superiores.

4. Validacao Contínua com Mypy:
   - Mantenha a tipagem estrita livre de `# type: ignore`:
     ```bash
     mypy --config-file app/pyproject.toml src tests
     ```
