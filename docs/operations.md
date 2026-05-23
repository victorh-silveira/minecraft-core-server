# Operacao

## Checklist — primeiro boot

| # | Acao |
|---|------|
| 1 | `Copy-Item .env.example .env` e preencher valores reais |
| 2 | `pip install -r requirements-dev.txt` |
| 3 | `pre-commit install` e `pre-commit install --hook-type commit-msg` |
| 4 | `make docker-sync-mods` |
| 5 | `make docker-build-up` |
| 6 | `make docker-logs` — aguardar mensagem de servidor pronto |
| 7 | Conectar clientes em `host:GAME_PORT` (padrao 25565) |
| 8 | Configurar firewall RCON (secao abaixo) |
| 9 | Agendar backup de `src/domain/world-data` |

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
2. Editar `src/interface/mods/mods-manifest.json`
3. `make docker-sync-mods`
4. Testar localmente: `make docker-build-up`
5. Validar servidor in-game e logs
6. Merge apos estabilidade

Fixar `sha256` no manifesto apos validar em ambiente de teste.

---

## Backup do mundo

```powershell
Compress-Archive -Path src\domain\world-data -DestinationPath backup-world-$(Get-Date -Format yyyyMMdd-HHmm).zip
```

Restaurar: extrair para `src/domain/world-data` com servidor **parado** (`make docker-down`).

---

## Seguranca RCON

RCON expoe administracao remota. Em modo hibrido, restrinja acesso.

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
- Nunca commitar `.env`
- Preferir whitelist em servidores publicos
- Considerar mod de autenticacao com `online-mode=false`

---

## JARs, Git e sync de mods

JARs em `src/interface/mods/*.jar` estao no `.gitignore`. Apenas `mods-manifest.json` e versionado.

```powershell
make docker-sync-mods
pytest tests/unit/scripts/test_sync_mods.py
```

Se um JAR entrou no Git por engano:

```powershell
git rm --cached src/interface/mods/*.jar
```

---

## Persistencia de autenticacao

Pasta `src/infrastructure/database` montada em `/data/database` no container.

| Loader | Observacao |
|--------|------------|
| Fabric (atual) | AuthMe **nao** funciona; use mods Fabric (ex.: EasyAuth) |
| Paper/Spigot | AuthMe pode usar `/data/database` ou `/data/plugins/AuthMe/` |

Configure o mod/plugin para gravar SQLite em caminho persistente sob `/data/database`.

Backup:

```powershell
Copy-Item -Recurse src\infrastructure\database backup-auth-$(Get-Date -Format yyyyMMdd)
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

1. Verifique pastas em `src/domain`, `src/interface`, `src/infrastructure`
2. Ajuste `UID`/`GID` no `.env` se necessario
3. No WSL, prefira clonar o repo dentro do filesystem Linux (`~/`), nao em `/mnt/c/`

---

| Sintoma | Acao |
|---------|------|
| Container reinicia em loop | `make docker-logs` — verificar EULA, VERSION, TYPE |
| Mods nao carregam | `make docker-sync-mods`; conferir JARs em `src/interface/mods/` |
| Porta em uso | Alterar `GAME_PORT` no `.env` |
| `.env` nao encontrado | Copie `.env.example` para `.env` |
| Healthcheck failing | Aguardar start-period (180s); Fabric + mods demoram |
| Read-only file system em server.properties | Remover `read_only` do volume; itzg precisa gravar propriedades do `.env` no arquivo |
| Permission denied em /data | Ajustar UID/GID no `.env`; preferir repo em filesystem Linux no WSL |

---

## Parada e limpeza

| Comando | Efeito |
|---------|--------|
| `make docker-down` | Para e remove containers/rede |
| `make docker-clean` | + remove imagens locais e volumes anonimos |

`docker-clean` **nao** apaga `src/domain/world-data` (bind mount, nao volume nomeado).
