from typing import Protocol

from domain.entities.mod_manifest import ModManifest


class ManifestLoader(Protocol):
    def load(self) -> ModManifest:
        raise NotImplementedError
