---
name: mcs-hexagonal-tdd
description: >-
  Implementa alteracoes e novas funcionalidades no codigo Python utilizando Arquitetura
  Hexagonal e Desenvolvimento Orientado a Testes (TDD). Use when creating or modifying
  entities, value objects, domain services, use cases, ports, adapters, or CLI commands.
---

# Habilidade: mcs-hexagonal-tdd

Guia de execucao de mudancas no codigo Python respeitando as fronteiras hexagonais e a ordem do ciclo TDD.

## Procedimento Passo a Passo

1. Modelagem no Dominio:
   - Crie ou altere entidades e value objects em `app/src/domain/entities/`.
   - Implemente validacoes de regras de negocio e invariantes no construtor.
   - Crie testes unitarios em `app/tests/unit/domain/` sem uso de mocks.

2. Casos de Uso e Portas na Aplicacao:
   - Defina os contratos de saida (Ports) em `app/src/application/ports/` como `typing.Protocol`.
   - Implemente o caso de uso em `app/src/application/use_cases/`, recebendo as portas via injecao no construtor.
   - Crie testes unitarios em `app/tests/unit/application/` utilizando implementacoes fake em memoria das portas.

3. Adaptadores Concretos na Infraestrutura:
   - Implemente o adaptador em `app/src/infrastructure/adapters/`, consumindo bibliotecas externas (ex: `requests`) ou disco.
   - Isole a conversao de payloads externos em DTOs internos antes de instanciar entidades de dominio.
   - Adicione testes de integracao em `app/tests/integration/` ou `app/tests/unit/infrastructure/` cobrindo cenarios de sucesso e falhas de rede/I-O.

4. Composition Root na Camada Presentation:
   - Conecte as configuracoes (`Settings`), instancie os adaptadores e injete-os no caso de uso em `app/src/presentation/cli/main.py`.
   - Valide a chamada do CLI criando testes em `app/tests/unit/presentation/`.

5. Validacao de Conformidade:
   - Execute no terminal WSL:
     ```bash
     make app-lint
     make app-validate
     make app-test
     ```
   - Confirme que a cobertura branch permaneceu em 100% e que nenhum arquivo ultrapassa 300 linhas.
