from dataclasses import dataclass

from domain.entities.identifiers import Sha256Digest


@dataclass(frozen=True)
class ModrinthFileDto:
    url: str
    sha256: Sha256Digest


def pick_primary_file(files: list[object], mod_id: str) -> dict[str, object]:
    if not files:
        raise ValueError(f"Mod {mod_id}: arquivo Modrinth ausente")
    preferred = next(
        (item for item in files if isinstance(item, dict) and item.get("primary") is True),
        None,
    )
    primary = preferred if preferred is not None else files[0]
    if not isinstance(primary, dict):
        raise ValueError(f"Mod {mod_id}: arquivo Modrinth invalido")
    return primary


def map_modrinth_file(primary: dict[str, object], mod_id: str) -> ModrinthFileDto:
    url = primary.get("url")
    if not isinstance(url, str) or not url.strip():
        raise ValueError(f"Mod {mod_id}: url Modrinth ausente")
    sha256 = Sha256Digest("")
    hashes = primary.get("hashes", {})
    if isinstance(hashes, dict):
        raw = hashes.get("sha256") or ""
        if isinstance(raw, str):
            sha256 = Sha256Digest(raw)
    return ModrinthFileDto(url.strip(), sha256)
