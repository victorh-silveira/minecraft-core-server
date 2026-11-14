"""Adaptador de armazenamento local de arquivos JAR de mods."""

import hashlib
from pathlib import Path

from domain.entities.identifiers import Sha256Digest


class LocalJarStore:
    """Gerencia leitura, verificacao SHA-256 e remocao de JARs em disco."""

    def __init__(self, directory: Path) -> None:
        """Inicializa o repositorio local apontando para o diretorio de mods."""
        self._directory = directory

    def path_for(self, filename: str) -> Path:
        """Retorna o caminho completo para o arquivo JAR informado."""
        return self._directory / filename

    def prepare(self) -> None:
        """Garante a existencia do diretorio de armazenamento local."""
        self._directory.mkdir(parents=True, exist_ok=True)

    def exists(self, filename: str) -> bool:
        """Indica se o arquivo JAR ja esta presente em disco."""
        return self.path_for(filename).is_file()

    def digest(self, filename: str) -> Sha256Digest:
        """Calcula o digest SHA-256 do arquivo JAR armazenado."""
        digest = hashlib.sha256()
        with self.path_for(filename).open("rb") as handle:
            for chunk in iter(lambda: handle.read(8192), b""):
                digest.update(chunk)
        return Sha256Digest(digest.hexdigest())

    def remove(self, filename: str) -> None:
        """Remove o arquivo JAR do disco caso esteja presente."""
        self.path_for(filename).unlink(missing_ok=True)
