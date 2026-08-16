from infrastructure.adapters.http_client import RequestsHttpClient
from infrastructure.adapters.local_jar_store import LocalJarStore


class RequestsArtifactDownloader:
    def __init__(self, http: RequestsHttpClient, store: LocalJarStore) -> None:
        self._http = http
        self._store = store

    def download(self, url: str, filename: str) -> None:
        self._http.download(url, self._store.path_for(filename))
