---
name: mcs-ops-runbook
description: >-
  Runbook de operacoes do servidor Minecraft Forge em producao (AKS) e local (Docker).
  Cobre backup e restauracao de mundo, comandos via RCON, gestao de annotations de rede
  e troubleshooting. Use when managing Kubernetes deployments, backups, or server maintenance.
---

# Habilidade: mcs-ops-runbook

Procedimentos de campo para operacao, sustentacao e contingencia do servidor Minecraft Forge.

## Rotinas Operacionais

1. Inspecao de Saude e Status no Cluster AKS:
   - Conecte ao cluster e verifique os pods:
     ```bash
     az aks get-credentials -g rg-minecraft-server-prod -n aks-minecraft-server-prod
     kubectl get pods -n minecraft-server-prod -l app.kubernetes.io/name=minecraft-server
     ```
   - Obtenha o IP publico do LoadBalancer:
     ```bash
     kubectl get svc mc-server-game -n minecraft-server-prod
     ```

2. Execucao de Comandos via RCON:
   - Envie comandos administrativos para o servidor sem expor terminal interativo:
     ```bash
     kubectl exec -it mc-server-0 -n minecraft-server-prod -c minecraft -- rcon-cli "op AnonymousNoobz"
     kubectl exec -it mc-server-0 -n minecraft-server-prod -c minecraft -- rcon-cli "whitelist list"
     ```

3. Procedimento de Backup do Mundo:
   - Pause temporariamente a escrita em disco com salvamento forçado via RCON:
     ```bash
     kubectl exec -i mc-server-0 -n minecraft-server-prod -c minecraft -- rcon-cli "save-off"
     kubectl exec -i mc-server-0 -n minecraft-server-prod -c minecraft -- rcon-cli "save-all flush"
     ```
   - Crie o snapshot do volume de dados e reative o salvamento automatico:
     ```bash
     kubectl exec -i mc-server-0 -n minecraft-server-prod -c minecraft -- rcon-cli "save-on"
     ```

4. Troubleshooting de Inicializacao:
   - Em caso de falha de boot (CrashLoopBackOff), inspecione os logs do contêiner Forge:
     ```bash
     kubectl logs mc-server-0 -n minecraft-server-prod -c minecraft --tail=200
     ```
   - Verifique conflitos de memoria ou incompatibilidade de versoes nos arquivos de log.
