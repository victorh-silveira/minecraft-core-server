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
