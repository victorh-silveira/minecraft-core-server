from dataclasses import dataclass

from domain.entities.identifiers import Sha256Digest


@dataclass(frozen=True)
class DownloadArtifact:
    url: str
    sha256: Sha256Digest

    def __post_init__(self) -> None:
        stripped = self.url.strip()
        if not stripped:
            raise ValueError("url de download e obrigatoria")
        object.__setattr__(self, "url", stripped)
