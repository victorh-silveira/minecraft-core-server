# Operacao

Guia operacional para Docker local e Azure AKS. Arquitetura: [architecture.md](architecture.md). Deploy cloud: [azure.md](azure.md).

## Checklist — primeiro boot (local)

| # | Acao |
|---|------|
| 1 | `Copy-Item infra/docker/.env.example infra/docker/.env` e preencher valores reais |
| 2 | `make app-setup` |
| 3 | `make docker-sync-mods` |
| 4 | `make docker-up` |
| 5 | `make docker-logs` — aguardar mensagem de servidor pronto |
| 6 | Conectar clientes em `host:GAME_PORT` (padrao 25565) |
| 7 | Configurar firewall RCON (secao abaixo) |
| 8 | Agendar backup de `app/runtime/world` |

---

## Operacao diaria

```powershell
make docker-logs
make docker-restart
```

Shell administrativo:

```powershell
make docker-sh
```

---

## Atualizacao de mods

1. Criar branch: `feature/atualizar-mods`
2. Editar `app/runtime/mods/mods-manifest.json`
3. `make docker-sync-mods`
4. Testar localmente: `make docker-up`
5. Validar servidor in-game e logs
6. Merge apos estabilidade

Fixar `sha256` no manifesto apos validar em ambiente de teste.

---

## Backup do mundo

```powershell
Compress-Archive -Path app\runtime\world -DestinationPath backup-world-$(Get-Date -Format yyyyMMdd-HHmm).zip
```

Restaurar: extrair para `app/runtime/world` com servidor **parado** (`make docker-down`).

---

## Seguranca RCON

RCON expoe administracao remota. Restrinja acesso (localhost no Docker, port-forward no AKS).

### Windows Firewall (localhost)

Ajuste a porta se `RCON_PORT` no `.env` for diferente de `25575`.

```powershell
New-NetFirewallRule -DisplayName "Minecraft RCON Localhost" `
  -Direction Inbound -Protocol TCP -LocalPort 25575 `
  -Action Allow -RemoteAddress 127.0.0.1

New-NetFirewallRule -DisplayName "Minecraft RCON Block External" `
  -Direction Inbound -Protocol TCP -LocalPort 25575 `
  -Action Block -RemoteAddress Any
```

Para VPN de gerenciamento, substitua `127.0.0.1` pelo CIDR da rede privada.

### Boas praticas

- `RCON_PASSWORD` forte e unico no `.env`
- `MINECRAFT_WHITELIST` com nicks Mojang permitidos
- `ONLINE_MODE=false` (sem autenticacao Mojang)
- Nunca commitar `.env`
- Guia completo: [access-and-hostname.md](access-and-hostname.md)

---

## JARs, Git e sync de mods

JARs em `app/runtime/mods/*.jar` estao no `.gitignore`. Apenas `mods-manifest.json` e versionado.

```powershell
make docker-sync-mods
make app-test
```

Se um JAR entrou no Git por engano:

```powershell
git rm --cached app/runtime/mods/*.jar
```

---

## Persistencia de autenticacao

Pasta `app/runtime/database` montada em `/data/database` no container.

| Loader | Observacao |
|--------|------------|
| Fabric (atual) | AuthMe **nao** funciona; use mods Fabric (ex.: EasyAuth) |
| Paper/Spigot | AuthMe pode usar `/data/database` ou `/data/plugins/AuthMe/` |

Configure o mod/plugin para gravar SQLite em caminho persistente sob `/data/database`.

Backup:

```powershell
Copy-Item -Recurse app\runtime\database backup-auth-$(Get-Date -Format yyyyMMdd)
```

---

## Permissoes de volume (UID/GID)

Variaveis no `.env`:

```env
UID=1000
GID=1000
SKIP_CHOWN=false
```

A imagem itzg ajusta ownership de `/data` no init quando `SKIP_CHOWN=false`.

Se aparecer `Permission denied` nos logs:

1. Verifique pastas em `app/runtime/`
2. Ajuste `UID`/`GID` no `.env` se necessario
3. No WSL, prefira clonar o repo dentro do filesystem Linux (`~/`), nao em `/mnt/c/`

---

| Sintoma | Acao |
|---------|------|
| Container reinicia em loop | `make docker-logs` — verificar EULA, VERSION, TYPE |
| Mods nao carregam | `make docker-sync-mods`; conferir JARs em `app/runtime/mods/` |
| Porta em uso | Alterar `GAME_PORT` no `.env` |
| `.env` nao encontrado | Copie `infra/docker/.env.example` para `infra/docker/.env` |
| Healthcheck failing | Aguardar start-period (180s); Fabric + mods demoram |
| Read-only file system em server.properties | Remover `read_only` do volume; itzg precisa gravar propriedades do `.env` no arquivo |
| Permission denied em /data | Ajustar UID/GID no `.env`; preferir repo em filesystem Linux no WSL |

---

## Parada e limpeza

| Comando | Efeito |
|---------|--------|
| `make docker-down` | Para e remove containers/rede |
| `make docker-clean` | Remove containers, redes e volumes do projeto |

`docker-clean` **nao** apaga `app/runtime/world` (bind mount, nao volume nomeado).

---

## Operacao no Azure AKS

Guia completo: [azure.md](azure.md)

### Checklist — primeiro deploy AKS

| # | Acao |
|---|------|
| 1 | `infra/terraform/live/prod` — aplicar RG, VNet, ACR, AKS e storage |
| 2 | `az aks get-credentials` — configurar kubectl |
| 3 | Build e push da imagem para ACR |
| 4 | GitHub Secrets `RCON_PASSWORD` e `MINECRAFT_WHITELIST` |
| 5 | Workflow **CD** manual (`deploy-infra`, `APPLY_INFRA`) na primeira vez |
| 6 | Workflow **CD** na release ou `kubectl apply` + imagem no ACR |
| 7 | Migrar mundo: `kubectl cp` de `app/runtime/world` |
| 8 | `bash app/scripts/bash/test-aks.sh` |
| 9 | `make k8s-annotate` e ler `conectividade-endereco` no Service `mc-server-game` |

### Annotations (Azure, Kubernetes e Minecraft)

Referencia completa (catalogo, diagramas, todas as chaves): **[annotations.md](annotations.md)**.

Resumo operacional:

```bash
kubectl -n minecraft-server-prod get svc mc-server-game \
  -o jsonpath='{.metadata.annotations.minecraft-server\.io/conectividade-endereco}{"\n"}'
make k8s-annotate
```

O CD e o pos-deploy executam `atualizar-annotations-k8s.sh` apos o rollout.

### Backup do mundo (PVC)

Backup automatico (CronJob `mc-world-backup`, diario as 03:00 America/Sao_Paulo):

- Compacta `/data/world` no pod `mc-server-0` e envia para o blob `world-backups` em `stminecraftserverprod001`
- Autenticacao via Workload Identity (`id-mc-world-backup-prod`); requer `terraform apply` em `infra/terraform/live/prod` antes do primeiro deploy
- Custo marginal: armazenamento LRS dos arquivos `.tar.gz` (centavos por GB/mes)

Verificar ultimo job:

```bash
kubectl -n minecraft-server-prod get cronjob mc-world-backup
kubectl -n minecraft-server-prod get jobs -l app.kubernetes.io/name=mc-world-backup --sort-by=.metadata.creationTimestamp
az storage blob list --account-name stminecraftserverprod001 --container-name world-backups --auth-mode login -o table
```

Backup manual (com pod em execucao):

```bash
POD=$(kubectl -n minecraft-server-prod get pod -l app.kubernetes.io/name=mc-server -o jsonpath='{.items[0].metadata.name}')
kubectl -n minecraft-server-prod exec "$POD" -- tar czf /tmp/world-backup.tgz -C /data world
kubectl -n minecraft-server-prod cp "${POD}:/tmp/world-backup.tgz" "./backup-world-$(date +%Y%m%d).tgz"
```

Storage de backup e tfstate: `stminecraftserverprod001` (containers `world-backups` e `tfstate`).

### Disco persistente (Retain)

A StorageClass `mc-standard-ssd` usa `reclaimPolicy: Retain`. Se o StatefulSet ou PVC for removido, o disco gerenciado permanece no Azure (custo continua ate exclusao manual no portal). Volumes ja provisionados com `Delete` nao mudam automaticamente; migre apenas se necessario.

### RCON no AKS

O servico `mc-server-rcon` e **ClusterIP** (sem Load Balancer extra). Acesso administrativo:

```bash
kubectl port-forward -n minecraft-server-prod svc/mc-server-rcon 25575:25575
```

Senha: GitHub Secret `RCON_PASSWORD` (aplicada pelo CD) ou `kubectl create secret` local conforme `infra/kubernetes/base/secret-rcon.yaml.example`.

### Destroy e recursos orfaos

1. Actions > **Destroy** > confirmar `DESTROY` e aprovar environment.
2. Baixar artifact `terraform-destroy-plan-*` e revisar o plano.
3. Apos destroy, listar discos orfaos no portal Azure (PVC `Retain` pode manter discos).
4. O remote state em `stminecraftserverprod001` nao e destruido pelo workflow de destroy da stack prod.
