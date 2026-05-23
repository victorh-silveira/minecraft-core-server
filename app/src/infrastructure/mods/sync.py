import hashlib
import json
import sys

import requests

from infrastructure.mods import paths
from infrastructure.mods.curseforge import CurseForgeResolver, resolve_curseforge
from infrastructure.mods.http_client import api_get, download_jar
from infrastructure.mods.modrinth import ModrinthResolver, resolve_modrinth
from infrastructure.mods.providers import ModResolver


_RESOLVERS: dict[str, ModResolver] = {
    "modrinth": ModrinthResolver(),
    "curseforge": CurseForgeResolver(),
}


def load_manifest():
    with paths.MANIFEST_PATH.open(encoding="utf-8") as handle:
        return json.load(handle)


def sha256_file(path) -> str:
    digest = hashlib.sha256()
    with path.open("rb") as handle:
        for chunk in iter(lambda: handle.read(8192), b""):
            digest.update(chunk)
    return digest.hexdigest()


def jar_path(mod_id: str, version: str):
    safe_version = version.replace("/", "_")
    return paths.MODS_DIR / f"{mod_id}-{safe_version}.jar"


def resolve_download(mod_entry: dict, minecraft_version: str, loader: str):
    source = mod_entry.get("source", "").lower()
    resolver = _RESOLVERS.get(source)
    if resolver is None:
        raise ValueError(f"Mod {mod_entry['id']}: source desconhecida '{source}'")
    return resolver.resolve(mod_entry, minecraft_version, loader)


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
    if not paths.MANIFEST_PATH.is_file():
        print(f"Manifesto nao encontrado: {paths.MANIFEST_PATH}", file=sys.stderr)
        sys.exit(1)

    manifest = load_manifest()
    minecraft_version = manifest.get("minecraft_version", "1.20.6")
    loader = manifest.get("loader", "fabric")
    mods = manifest.get("mods", [])

    if not mods:
        print("Nenhum mod no manifesto.")
        return

    paths.MODS_DIR.mkdir(parents=True, exist_ok=True)
    failed = False

    for entry in mods:
        try:
            sync_mod(entry, minecraft_version, loader)
        except (requests.RequestException, ValueError, KeyError) as error:
            failed = True
            print(f"[erro] {entry.get('id', '?')}: {error}", file=sys.stderr)

    if failed:
        sys.exit(1)


__all__ = [
    "api_get",
    "download_jar",
    "load_manifest",
    "sha256_file",
    "jar_path",
    "resolve_modrinth",
    "resolve_curseforge",
    "resolve_download",
    "sync_mod",
    "main",
]
