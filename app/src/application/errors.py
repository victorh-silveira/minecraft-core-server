"""Excecoes semanticas da camada de aplicacao."""


class SyncFailedError(Exception):
    """Erro base para falhas na sincronizacao de mods."""


class ManifestNotFoundError(SyncFailedError):
    """Excecao lancada quando o arquivo de manifesto nao e encontrado."""

    def __init__(self, path: str) -> None:
        """Inicializa o erro com o caminho do manifesto ausente."""
        super().__init__(f"Manifesto nao encontrado: {path}")
        self.path = path


class ArtifactError(SyncFailedError):
    """Excecao lancada em falhas de resolucao ou download de artefatos."""
