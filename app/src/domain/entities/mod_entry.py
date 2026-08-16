from collections.abc import Mapping
from dataclasses import dataclass

from domain.entities.identifiers import ModId, ModVersion, Sha256Digest
from domain.entities.mod_source import ModSource


@dataclass(frozen=True)
class ModEntry:
    mod_id: ModId
    version: ModVersion
    source: ModSource
    project_slug: str | None
    download_url: str | None
    sha256: Sha256Digest

    @classmethod
    def from_mapping(cls, payload: object) -> "ModEntry":
        if not isinstance(payload, Mapping):
            raise ValueError("entrada de mod invalida")
        raw_id = payload.get("id")
        if not isinstance(raw_id, str):
            raise ValueError("id do mod e obrigatorio")
        raw_version = payload.get("version")
        if not isinstance(raw_version, str):
            raise ValueError("versao do mod e obrigatoria")
        raw_source = payload.get("source")
        if not isinstance(raw_source, str) or not raw_source.strip():
            raise ValueError(f"Mod {raw_id}: source e obrigatoria")
        try:
            source = ModSource(raw_source.strip().lower())
        except ValueError as error:
            raise ValueError(f"Mod {raw_id}: source desconhecida '{raw_source}'") from error
        slug_raw = payload.get("project_slug")
        project_slug = slug_raw.strip() if isinstance(slug_raw, str) and slug_raw.strip() else None
        url_raw = payload.get("download_url")
        download_url = url_raw.strip() if isinstance(url_raw, str) and url_raw.strip() else None
        sha_raw = payload.get("sha256", "")
        sha256 = Sha256Digest(sha_raw if isinstance(sha_raw, str) else "")
        return cls(
            mod_id=ModId(raw_id),
            version=ModVersion(raw_version),
            source=source,
            project_slug=project_slug,
            download_url=download_url,
            sha256=sha256,
        )
