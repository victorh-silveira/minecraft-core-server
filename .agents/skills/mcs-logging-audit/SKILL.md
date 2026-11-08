---
name: mcs-logging-audit
description: >-
  Audita e refatora a telemetria e o logging semantico da aplicacao. Assegura o uso
  exclusivo de log_event, mascara dados sensiveis e evita poluicao de logs em nivel INFO.
  Use when reviewing log statements, sanitizing URLs/tokens, or adjusting event logging.
---

# Habilidade: mcs-logging-audit

Instrucoes para auditoria de conformidade dos registros de log do projeto.

## Procedimento de Auditoria

1. Inspecao de Chamadas no Nucleo:
   - Execute uma busca por importacoes de logging ou chamadas diretas em `domain` e `application`:
     ```bash
     grep -rn "logging" app/src/domain/ app/src/application/
     ```
   - Nenhuma ocorrencia e permitida; caso encontre, remova-as e faca o registro na camada de adaptadores ou presentation.

2. Verificacao de Mascaramento de Segredos:
   - Inspecione chamadas a `log_event` em `app/src/infrastructure/` e `app/src/presentation/`.
   - Garanta que URLs com credenciais ou parametros de query nao sejam impressas diretamente.
   - Certifique-se de que nenhum token ou chave de API seja enviado aos campos de telemetria.

3. Validacao do Volume de Informacoes:
   - Assegure que no caminho feliz (happy path) de sincronizacao de mods sejam emitidas apenas ~3 mensagens em nivel INFO:
     1. Evento de inicio (`mods.sync.started`).
     2. Evento de progresso/sumario (`mods.sync.completed`).
     3. Evento de fechamento de ciclo.
   - Dumps de manifesto JSON bruto ou respostas HTTP completas devem ser restritos a DEBUG ou eliminados.

4. Testes de Telemetria:
   - Execute os testes unitarios de logging para garantir a captura correta dos eventos:
     ```bash
     pytest app/tests/unit/presentation/test_cli.py
     ```
