from typing import Protocol


class ArtifactDownloader(Protocol):
    def download(self, url: str, filename: str) -> None:
        raise NotImplementedError
