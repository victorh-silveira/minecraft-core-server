"""Adaptador de download de artefatos via cliente HTTP."""

from infrastructure.adapters.http_client import RequestsHttpClient
from infrastructure.adapters.local_jar_store import LocalJarStore


class RequestsArtifactDownloader:
    """Executa o download de artefatos diretamente para o LocalJarStore."""

    def __init__(self, http: RequestsHttpClient, store: LocalJarStore) -> None:
        """Inicializa o downloader com cliente HTTP e repositorio local."""
        self._http = http
        self._store = store

    def download(self, url: str, filename: str) -> None:
        """Baixa o artefato da URL informada para o destino no store."""
        self._http.download(url, self._store.path_for(filename))
