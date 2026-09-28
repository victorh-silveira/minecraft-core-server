# Infra Docker

Entrega local do servidor Forge 26.3 sem mods e sem whitelist. Stack Azure: [architecture.md](architecture.md) e [azure.md](azure.md).

## Artefatos

| Arquivo | Papel |
|---------|-------|
| [`infra/docker/Dockerfile`](../infra/docker/Dockerfile) | Imagem baseada em `itzg/minecraft-server:java25` |
| [`infra/docker/docker-compose.yml`](../infra/docker/docker-compose.yml) | Servico `mc-server` |
| [`infra/docker/.env.example`](../infra/docker/.env.example) | Variaveis do Compose (copiar para `.env`) |
| [`app/runtime/configs/server-icon.png`](../app/runtime/configs/server-icon.png) | Icone PNG 64x64 exibido na lista de servidores |

O Compose usa `infra/docker/.env`, nao o `.env` da raiz. A raiz [`.env.example`](../.env.example) documenta tambem as vars do sync Python.

## Volume (`app/runtime/` → `/data`)

O Compose monta `app/runtime` integralmente em `/data`. Antes de subir o container, `docker-compose-up.sh` copia o template versionado `app/runtime/configs/server.properties` para `app/runtime/server.properties`. O servidor modifica apenas a copia ignorada pelo Git.

O bind unico garante que `world`, `world upgraded` e os temporarios de `world/filefix` estejam no mesmo filesystem. Isso e obrigatorio para a troca atomica usada pela migracao de mundos do Minecraft 26.3 e evita `Invalid cross-device link`.

Templates copiados na imagem: `server.properties`, `server-icon.png` e `mods-manifest.json`. A imagem itzg materializa o icone em `/data/server-icon.png`; bind mounts locais prevalecem em runtime.

O Compose fixa `VERSION=26.3`, `TYPE=FORGE` e `FORGE_VERSION=66.0.6` pelos defaults dos templates. Whitelist e perfil seguro ficam desabilitados. No boot, ativa `keepInventory`, permite avancar a noite com um jogador e silencia feedback administrativo; em cada conexao, `op AnonymousNoobz` garante OP nivel 4 ao administrador.

## Recursos e escalamento

O servidor usa escalamento vertical. Uma unica world nao pode ser executada por varias replicas gravando o mesmo estado; por isso, Docker e StatefulSet mantem uma instancia e dimensionam CPU e memoria.

| Variavel local | Padrao | Funcao |
|----------------|--------|--------|
| `MINECRAFT_INIT_MEMORY` | `1G` | Heap inicial da JVM |
| `MINECRAFT_MAX_MEMORY` | `1536M` | Heap maximo da JVM |
| `DOCKER_CPU_LIMIT` | `4.0` | Teto de CPUs logicas do container |
| `DOCKER_MEMORY_LIMIT` | `2G` | Limite rigido total do container |
| `DOCKER_MEMORY_RESERVATION` | `1536M` | Reserva suave de memoria |
| `DOCKER_MEMORY_SWAP_LIMIT` | `2G` | Memoria mais swap; igual ao limite desabilita swap adicional |
| `DOCKER_PIDS_LIMIT` | `512` | Limite de processos/threads |
| `DOCKER_TMPFS_LIMIT` | `256m` | Limite do `/tmp` volátil em memoria |

O heap maximo fica 512 MiB abaixo do limite total para Metaspace, buffers nativos, threads e Forge. Nao configure `MINECRAFT_MAX_MEMORY` igual a `DOCKER_MEMORY_LIMIT`: isso causa pressao de memoria, swap e risco de OOM. Para aumentar capacidade, preserve pelo menos 25% de folga nativa e ajuste CPU/memoria de forma conjunta.

A imagem final executa diretamente como UID/GID `1000`. Uma etapa privilegiada de build remove `gosu` e `restify`, desnecessarios no runtime Forge non-root; nenhum processo final executa como root. No runtime, `no-new-privileges`, `cap_drop: ALL` e filesystem raiz somente leitura reduzem escalacao e persistencia fora de `/data`. O `/tmp` usa tmpfs limitado a 256 MiB; PID 1 usa o init do Compose e o encerramento recebe `SIGTERM` com 60 segundos para salvar a world.

A maior parte da imagem vem da base oficial `itzg` com Java 25. O runtime acrescenta aproximadamente 42 MiB para versoes corrigidas de `mc-monitor`, `rcon-cli` e bibliotecas do `mc-image-helper`; compilador Go, Git, fontes e caches existem apenas no estagio intermediario e nao entram na imagem final. A variante Alpine e menor, mas nao e adotada enquanto nao oferecer a mesma previsibilidade de bibliotecas nativas do Forge e uma superficie de vulnerabilidades menor.

O estagio `security-builder` usa imagem Go fixada por digest, commits exatos dos dois utilitarios, dependencias Go corretivas e JARs do Maven Central verificados por SHA-256. Os arquivos corrigidos preservam os nomes esperados pelo classpath do `mc-image-helper`. Esse overlay deve ser removido quando uma nova base `itzg` pinada incorporar versoes iguais ou superiores; ate la, `Docker | Imagem segura` executa Trivy apos o build no CI e bloqueia HIGH/CRITICAL com correcao disponivel.

## Comandos

```bash
Copy-Item infra/docker/.env.example infra/docker/.env
make docker-up
make docker-logs
make docker-smoke
```

`make docker-smoke` executa handshake de status do protocolo Minecraft, alem do teste TCP:

1. Local: `127.0.0.1:GAME_PORT`.
2. LAN: `SMOKE_LAN_HOST:GAME_PORT`.
3. WAN: obtem o IP publico pelo JSON de `SMOKE_IPIFY_URL` e usa `SMOKE_EXTERNAL_STATUS_URL` para testar externamente `SMOKE_WAN_PORT` e o protocolo Minecraft.
4. DNS/WAN: exige que `SMOKE_DNS_HOST` resolva para o IP publico e confirma externamente porta, protocolo e MOTD esperado.

O padrao de DNS e `noobz.ddns.net`. O teste externo e autoritativo; tentativas adicionais pelo IP WAN e DNS a partir da LAN produzem apenas aviso quando o roteador nao oferece NAT loopback. A API externa pode manter cache por ate cinco minutos.

A exposicao LAN usa o bind `0.0.0.0:GAME_PORT` do Docker dentro do WSL. O bootstrap detecta o IP atual do WSL e recria o `netsh portproxy` do Windows apontando para esse IP, alem de liberar a porta no Firewall. O destino nunca deve ser `127.0.0.1`, pois isso cria um loop no listener do IP Helper.

O smoke aguarda ate `SMOKE_STARTUP_TIMEOUT_SEC` antes de testar conexoes; o padrao de 900 segundos contempla o download e a instalacao inicial do Forge. Durante a espera, exibe o estado do healthcheck e o tamanho parcial do instalador.

O manifesto de mods permanece vazio. `python run.py` (Makefile `docker-sync-mods`) valida esse estado e remove JARs gerenciados que nao estejam declarados; JARs nao entram no Git.
