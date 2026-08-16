from typing import Protocol

from domain.entities.download_artifact import DownloadArtifact
from domain.entities.mod_entry import ModEntry


class ModResolver(Protocol):
    def resolve(self, entry: ModEntry, minecraft_version: str, loader: str) -> DownloadArtifact:
        raise NotImplementedError
