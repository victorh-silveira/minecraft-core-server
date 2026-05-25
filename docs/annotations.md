# Annotations Kubernetes

Metadados `minecraft-server.io/*` reduzidos a **14 informacoes essenciais** (conectividade, saude, jogo, backup e documentacao).

## Fluxo de metadados

```mermaid
flowchart LR
  subgraph estatico [Manifestos]
    patch[annotations-recursos.yaml]
  end
  subgraph runtime [Apos deploy]
    script[atualizar-annotations-k8s.sh]
    lb[LoadBalancer Azure]
  end
  subgraph github [GitHub Actions]
    summary[Summary do workflow]
  end
  patch --> script
  lb --> script
  script --> summary
```

| Origem | Quando | O que define |
|--------|--------|--------------|
| `infra/kubernetes/overlays/prod/patches/annotations-recursos.yaml` | `kubectl apply -k` | Ambiente, jogo, DNS, backup, doc |
| `app/scripts/bash/atualizar-annotations-k8s.sh` | CD, `make k8s-annotate` | Host, endereco, LB, saude TCP/logs, timestamp |
| `app/scripts/bash/publicar-annotations-github.sh` | CI e CD | Tabela resumida no Summary do GitHub |

## GitHub Actions (onde ver no portal)

O painel **Annotations** do job mostra avisos do runner. O resumo operacional esta na aba **Summary**:

| Job | Conteudo |
|-----|----------|
| CI - Validacao | Ate 14 linhas estaticas |
| CD - Deploy App / Pos-deploy | Valores ao vivo do cluster |

## Catalogo essencial (14 chaves)

| Chave | Informacao no Summary | Estatico / dinamico |
|-------|----------------------|---------------------|
| `minecraft-server.io/ambiente` | Ambiente | Estatico |
| `minecraft-server.io/conectividade-endereco` | Endereco Minecraft | Dinamico |
| `minecraft-server.io/conectividade-host` | Host publico | Dinamico |
| `minecraft-server.io/conectividade-loadbalancer` | Load Balancer | Dinamico |
| `minecraft-server.io/conectividade-porta` | Porta do jogo | Estatico |
| `minecraft-server.io/saude-tcp-externa` | Porta 25565 TCP | Dinamico |
| `minecraft-server.io/saude-statefulset` | Replicas prontas | Dinamico |
| `minecraft-server.io/saude-logs` | Estado nos logs | Dinamico |
| `minecraft-server.io/jogo-versao` | Versao Minecraft | Estatico |
| `minecraft-server.io/jogo-tipo` | Loader | Estatico |
| `minecraft-server.io/azure-dns-fqdn-esperado` | DNS Azure esperado | Estatico |
| `minecraft-server.io/backup-agendamento` | Backup cron | Estatico |
| `minecraft-server.io/documentacao-acesso` | Documentacao | Estatico |
| `minecraft-server.io/atualizado-em` | Ultima atualizacao | Dinamico |

## Consulta rapida

Endereco para jogar:

```bash
kubectl -n minecraft-server-prod get svc mc-server-game \
  -o jsonpath='{.metadata.annotations.minecraft-server\.io/conectividade-endereco}{"\n"}'
```

Atualizar valores dinamicos:

```bash
make k8s-annotate
```

Listar chaves essenciais no StatefulSet:

```bash
kubectl -n minecraft-server-prod get statefulset mc-server -o json | \
  jq -r '.metadata.annotations | to_entries[] | select(.key | startswith("minecraft-server.io/")) | "\(.key)=\(.value)"'
```

## Workload Identity (backup)

A ServiceAccount `mc-world-backup` usa `azure.workload.identity/client-id` (substituido no CD). Nao faz parte das 14 chaves `minecraft-server.io/*`.

## Diagrama de conectividade

```mermaid
flowchart LR
  player[Jogador]
  lb[Service mc-server-game LoadBalancer]
  pod[Pod mc-server-0 :25565]
  ann[annotation conectividade-endereco]
  player --> lb --> pod
  lb --> ann
```
