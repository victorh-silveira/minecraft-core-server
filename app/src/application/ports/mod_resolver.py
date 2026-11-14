"""Porta para resolucao de artefatos de mods por provedor."""

from typing import Protocol

from domain.entities.download_artifact import DownloadArtifact
from domain.entities.mod_entry import ModEntry


class ModResolver(Protocol):
    """Contrato para resolver URL e hash SHA-256 de um mod."""

    def resolve(self, entry: ModEntry, minecraft_version: str, loader: str) -> DownloadArtifact:
        """Resolve os metadados de download para a versao e loader informados."""
        raise NotImplementedError
