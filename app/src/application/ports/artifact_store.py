"""Porta para persistencia e verificacao local de arquivos JAR."""

from typing import Protocol

from domain.entities.identifiers import Sha256Digest


class ArtifactStore(Protocol):
    """Contrato para operacoes sobre o repositorio local de JARs."""

    def prepare(self) -> None:
        """Prepara o diretorio local de armazenamento de artefatos."""
        raise NotImplementedError

    def exists(self, filename: str) -> bool:
        """Verifica se o arquivo ja existe no armazenamento local."""
        raise NotImplementedError

    def digest(self, filename: str) -> Sha256Digest:
        """Calcula o digest SHA-256 do arquivo armazenado."""
        raise NotImplementedError

    def remove(self, filename: str) -> None:
        """Remove o arquivo do armazenamento local caso exista."""
        raise NotImplementedError
