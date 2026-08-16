import hashlib
from pathlib import Path

from domain.entities.identifiers import Sha256Digest


class LocalJarStore:
    def __init__(self, directory: Path) -> None:
        self._directory = directory

    def path_for(self, filename: str) -> Path:
        return self._directory / filename

    def prepare(self) -> None:
        self._directory.mkdir(parents=True, exist_ok=True)

    def exists(self, filename: str) -> bool:
        return self.path_for(filename).is_file()

    def digest(self, filename: str) -> Sha256Digest:
        digest = hashlib.sha256()
        with self.path_for(filename).open("rb") as handle:
            for chunk in iter(lambda: handle.read(8192), b""):
                digest.update(chunk)
        return Sha256Digest(digest.hexdigest())

    def remove(self, filename: str) -> None:
        self.path_for(filename).unlink(missing_ok=True)
