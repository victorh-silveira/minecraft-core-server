"""Objeto de valor que representa um artefato de download resolvido."""

from dataclasses import dataclass

from domain.entities.identifiers import Sha256Digest


@dataclass(frozen=True)
class DownloadArtifact:
    """Artefato imutavel com URL de download e digest SHA-256."""

    url: str
    sha256: Sha256Digest

    def __post_init__(self) -> None:
        """Normaliza e valida a obrigatoriedade da URL de download."""
        stripped = self.url.strip()
        if not stripped:
            raise ValueError("url de download e obrigatoria")
        object.__setattr__(self, "url", stripped)
