import json
import sys

from gates_common import REPO_ROOT


MANIFEST = REPO_ROOT / "app" / "runtime" / "mods" / "mods-manifest.json"
REQUIRED_ROOT = {"schema_version", "minecraft_version", "loader", "mods"}
REQUIRED_MOD = {"id", "version", "source"}


def stage_validate() -> None:
    print("\n>>> Executando: JSON validate (parse)")
    if not MANIFEST.is_file():
        print(f"[ERRO] Manifesto ausente: {MANIFEST}")
        sys.exit(1)
    try:
        json.loads(MANIFEST.read_text(encoding="utf-8"))
    except json.JSONDecodeError as error:
        print(f"[ERRO] JSON invalido em {MANIFEST}: {error}")
        sys.exit(1)
    print(f"[OK] JSON valido: {MANIFEST.relative_to(REPO_ROOT)}")


def stage_lint() -> None:
    print("\n>>> Executando: JSON lint (schema do manifesto)")
    stage_validate()
    data = json.loads(MANIFEST.read_text(encoding="utf-8"))
    missing = REQUIRED_ROOT - set(data)
    if missing:
        print(f"[ERRO] Campos raiz ausentes: {sorted(missing)}")
        sys.exit(1)
    if not isinstance(data["schema_version"], int):
        print("[ERRO] schema_version deve ser int")
        sys.exit(1)
    if not isinstance(data["minecraft_version"], str) or not data["minecraft_version"]:
        print("[ERRO] minecraft_version deve ser string nao vazia")
        sys.exit(1)
    if data["loader"] not in {"fabric", "forge", "neoforge", "quilt"}:
        print(f"[ERRO] loader invalido: {data['loader']}")
        sys.exit(1)
    mods = data["mods"]
    if not isinstance(mods, list) or not mods:
        print("[ERRO] mods deve ser lista nao vazia")
        sys.exit(1)
    for index, entry in enumerate(mods):
        if not isinstance(entry, dict):
            print(f"[ERRO] mods[{index}] deve ser objeto")
            sys.exit(1)
        absent = REQUIRED_MOD - set(entry)
        if absent:
            print(f"[ERRO] mods[{index}] sem campos: {sorted(absent)}")
            sys.exit(1)
        if entry["source"] not in {"modrinth", "curseforge"}:
            print(f"[ERRO] mods[{index}].source invalido: {entry['source']}")
            sys.exit(1)
    print("[OK] Manifesto de mods passou no lint estrutural.")


def _mods() -> list[dict[str, object]]:
    stage_validate()
    data = json.loads(MANIFEST.read_text(encoding="utf-8"))
    mods = data["mods"]
    if not isinstance(mods, list):
        print("[ERRO] mods deve ser lista")
        sys.exit(1)
    return [entry for entry in mods if isinstance(entry, dict)]


def stage_security() -> None:
    print("\n>>> Executando: JSON seguranca (https e sha256)")
    for index, entry in enumerate(_mods()):
        url = entry.get("download_url")
        if isinstance(url, str) and url and not url.startswith("https://"):
            print(f"[ERRO] mods[{index}].download_url deve ser https")
            sys.exit(1)
        sha_raw = entry.get("sha256")
        if sha_raw is None or sha_raw == "":
            continue
        if (
            not isinstance(sha_raw, str)
            or len(sha_raw) != 64
            or any(ch not in "0123456789abcdefABCDEF" for ch in sha_raw)
        ):
            print(f"[ERRO] mods[{index}].sha256 invalido")
            sys.exit(1)
    print("[OK] manifesto sem URL insegura e com sha256 valido quando presente.")


def stage_test() -> None:
    print("\n>>> Executando: JSON testes (ids unicos)")
    seen: set[str] = set()
    for index, entry in enumerate(_mods()):
        mod_id = entry.get("id")
        if not isinstance(mod_id, str) or not mod_id:
            print(f"[ERRO] mods[{index}].id ausente")
            sys.exit(1)
        if mod_id in seen:
            print(f"[ERRO] id duplicado: {mod_id}")
            sys.exit(1)
        seen.add(mod_id)
    print("[OK] ids de mods unicos.")


def stage_build() -> None:
    print("\n>>> Executando: JSON build (sha256 obrigatorio)")
    for index, entry in enumerate(_mods()):
        sha_raw = entry.get("sha256")
        if not isinstance(sha_raw, str) or len(sha_raw) != 64:
            print(f"[ERRO] mods[{index}] sem sha256 de 64 hex (build)")
            sys.exit(1)
    print("[OK] manifesto pronto para sync (hash em todos os mods).")
