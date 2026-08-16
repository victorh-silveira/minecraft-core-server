from typing import Protocol

from domain.entities.identifiers import Sha256Digest


class ArtifactStore(Protocol):
    def prepare(self) -> None:
        raise NotImplementedError

    def exists(self, filename: str) -> bool:
        raise NotImplementedError

    def digest(self, filename: str) -> Sha256Digest:
        raise NotImplementedError

    def remove(self, filename: str) -> None:
        raise NotImplementedError
