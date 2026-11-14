"""Porta para download de artefatos de mods."""

from typing import Protocol


class ArtifactDownloader(Protocol):
    """Contrato para baixar um artefato remoto para o armazenamento local."""

    def download(self, url: str, filename: str) -> None:
        """Baixa o arquivo da URL informada com o nome de destino especificado."""
        raise NotImplementedError
