class SyncFailedError(Exception):
    pass


class ManifestNotFoundError(SyncFailedError):
    def __init__(self, path: str) -> None:
        super().__init__(f"Manifesto nao encontrado: {path}")
        self.path = path


class ArtifactError(SyncFailedError):
    pass
