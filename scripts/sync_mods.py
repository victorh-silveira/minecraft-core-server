import hashlib
import json
import sys
from pathlib import Path

import requests


ROOT = Path(__file__).resolve().parent.parent
MANIFEST_PATH = ROOT / "src" / "interface" / "mods" / "mods-manifest.json"
MODS_DIR = ROOT / "src" / "interface" / "mods"
MODRINTH_API = "https://api.modrinth.com/v2"
USER_AGENT = "minecraft-server-sync/1.0"


def load_manifest():
    with MANIFEST_PATH.open(encoding="utf-8") as handle:
        return json.load(handle)


def sha256_file(path: Path) -> str:
    digest = hashlib.sha256()
    with path.open("rb") as handle:
        for chunk in iter(lambda: handle.read(8192), b""):
            digest.update(chunk)
    return digest.hexdigest()


def jar_path(mod_id: str, version: str) -> Path:
    safe_version = version.replace("/", "_")
    return MODS_DIR / f"{mod_id}-{safe_version}.jar"


def api_get(path: str):
    response = requests.get(
        f"{MODRINTH_API}{path}",
        headers={"User-Agent": USER_AGENT},
        timeout=60,
    )
    response.raise_for_status()
    return response.json()


def resolve_modrinth(mod_entry: dict, minecraft_version: str, loader: str):
    download_url = (mod_entry.get("download_url") or "").strip()
    expected_sha256 = (mod_entry.get("sha256") or "").strip().lower()

    if download_url:
        return download_url, expected_sha256

    project_slug = mod_entry.get("project_slug")
    version = mod_entry["version"]
    if not project_slug:
        raise ValueError(f"Mod {mod_entry['id']}: informe download_url ou project_slug para source modrinth")

    versions = api_get(f'/project/{project_slug}/version?game_versions=["{minecraft_version}"]&loaders=["{loader}"]')
    match = next(
        (item for item in versions if item.get("version_number") == version),
        None,
    )
    if match is None:
        raise ValueError(
            f"Mod {mod_entry['id']}: versao {version} nao encontrada no Modrinth para {minecraft_version}/{loader}"
        )

    primary = match["files"][0]
    url = primary["url"]
    hashes = primary.get("hashes", {})
    if not expected_sha256:
        expected_sha256 = (hashes.get("sha256") or "").lower()
    return url, expected_sha256


def resolve_curseforge(mod_entry: dict):
    download_url = (mod_entry.get("download_url") or "").strip()
    expected_sha256 = (mod_entry.get("sha256") or "").strip().lower()
    if not download_url:
        raise ValueError(
            f"Mod {mod_entry['id']}: CurseForge requer download_url e CURSEFORGE_API_KEY no ambiente (nao implementado)"
        )
    return download_url, expected_sha256


def resolve_download(mod_entry: dict, minecraft_version: str, loader: str):
    source = mod_entry.get("source", "").lower()
    if source == "modrinth":
        return resolve_modrinth(mod_entry, minecraft_version, loader)
    if source == "curseforge":
        return resolve_curseforge(mod_entry)
    raise ValueError(f"Mod {mod_entry['id']}: source desconhecida '{source}'")


def download_jar(url: str, destination: Path):
    response = requests.get(
        url,
        headers={"User-Agent": USER_AGENT},
        stream=True,
        timeout=120,
    )
    response.raise_for_status()
    destination.parent.mkdir(parents=True, exist_ok=True)
    with destination.open("wb") as handle:
        for chunk in response.iter_content(chunk_size=8192):
            if chunk:
                handle.write(chunk)


def sync_mod(mod_entry: dict, minecraft_version: str, loader: str) -> bool:
    mod_id = mod_entry["id"]
    version = mod_entry["version"]
    destination = jar_path(mod_id, version)
    url, expected_sha256 = resolve_download(mod_entry, minecraft_version, loader)

    if destination.is_file():
        actual = sha256_file(destination)
        if expected_sha256 and actual == expected_sha256:
            print(f"[ok] {destination.name} ja sincronizado")
            return True
        if expected_sha256 and actual != expected_sha256:
            print(f"[atualizar] {destination.name} hash divergente, baixando novamente")
        elif not expected_sha256:
            print(f"[ok] {destination.name} existe (sem sha256 no manifesto para validar)")
            return True

    print(f"[baixar] {mod_id} {version}")
    download_jar(url, destination)

    actual = sha256_file(destination)
    if expected_sha256 and actual != expected_sha256:
        destination.unlink(missing_ok=True)
        raise ValueError(f"Mod {mod_id}: sha256 esperado {expected_sha256}, obtido {actual}")

    print(f"[ok] {destination.name} ({actual})")
    return True


def main():
    if not MANIFEST_PATH.is_file():
        print(f"Manifesto nao encontrado: {MANIFEST_PATH}", file=sys.stderr)
        sys.exit(1)

    manifest = load_manifest()
    minecraft_version = manifest.get("minecraft_version", "1.20.6")
    loader = manifest.get("loader", "fabric")
    mods = manifest.get("mods", [])

    if not mods:
        print("Nenhum mod no manifesto.")
        return

    MODS_DIR.mkdir(parents=True, exist_ok=True)
    failed = False

    for entry in mods:
        try:
            sync_mod(entry, minecraft_version, loader)
        except (requests.RequestException, ValueError, KeyError) as error:
            failed = True
            print(f"[erro] {entry.get('id', '?')}: {error}", file=sys.stderr)

    if failed:
        sys.exit(1)


if __name__ == "__main__":
    main()
