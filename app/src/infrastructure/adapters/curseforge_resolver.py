"""Adaptador de resolucao de artefatos para mods hospedados no CurseForge."""

from domain.entities.download_artifact import DownloadArtifact
from domain.entities.mod_entry import ModEntry


class CurseForgeResolver:
    """Resolve artefatos CurseForge a partir de URL e hash declarados."""

    def resolve(self, entry: ModEntry, _minecraft_version: str, _loader: str) -> DownloadArtifact:
        """Valida URL e SHA-256 obrigatorios e retorna o artefato de download."""
        if not entry.download_url:
            raise ValueError(f"Mod {entry.mod_id.value}: CurseForge requer download_url")
        if not entry.sha256.is_present():
            raise ValueError(f"Mod {entry.mod_id.value}: CurseForge requer sha256")
        return DownloadArtifact(entry.download_url, entry.sha256)
