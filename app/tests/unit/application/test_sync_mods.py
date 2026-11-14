"""Testes unitarios do caso de uso de sincronizacao de mods."""

from application.errors import ArtifactError
from application.use_cases.sync_mods import ModSyncStatus, SyncModsUseCase
from domain.entities.download_artifact import DownloadArtifact
from domain.entities.identifiers import Sha256Digest
from domain.entities.mod_entry import ModEntry
from domain.entities.mod_manifest import ModManifest
from domain.entities.mod_source import ModSource
from domain.services.jar_naming import jar_filename


SHA_A = "a" * 64
SHA_B = "b" * 64
SHA_C = "c" * 64
SHA_D = "d" * 64
SHA_F = "f" * 64


class FakeLoader:
    """Duble de ManifestLoader que retorna um manifesto em memoria."""

    def __init__(self, manifest: ModManifest) -> None:
        """Inicializa o carregador falso com o manifesto informado."""
        self._manifest = manifest

    def load(self) -> ModManifest:
        """Retorna o manifesto configurado."""
        return self._manifest


class FakeStore:
    """Duble em memoria de ArtifactStore para testes do caso de uso."""

    def __init__(self) -> None:
        """Inicializa o mapa de arquivos e flags de controle."""
        self.files: dict[str, str] = {}
        self.prepared = False
        self.removed: list[str] = []

    def prepare(self) -> None:
        """Marca o repositorio falso como preparado."""
        self.prepared = True

    def exists(self, filename: str) -> bool:
        """Verifica se o arquivo consta no mapa em memoria."""
        return filename in self.files

    def digest(self, filename: str) -> Sha256Digest:
        """Retorna o digest SHA-256 armazenado para o arquivo."""
        return Sha256Digest(self.files[filename])

    def remove(self, filename: str) -> None:
        """Registra a remocao e apaga o arquivo do mapa em memoria."""
        self.removed.append(filename)
        self.files.pop(filename, None)


class FakeDownloader:
    """Duble de ArtifactDownloader que grava hashes simulados no FakeStore."""

    def __init__(self, store: FakeStore, payloads: dict[str, str], error: str | None = None) -> None:
        """Inicializa o downloader falso com payloads esperados e erro opcional."""
        self._store = store
        self._payloads = payloads
        self._error = error
        self.calls: list[tuple[str, str]] = []

    def download(self, url: str, filename: str) -> None:
        """Registra a chamada e simula sucesso ou falha de download."""
        self.calls.append((url, filename))
        if self._error is not None:
            raise ArtifactError(self._error)
        self._store.files[filename] = self._payloads[filename]


class FakeResolver:
    """Duble de ModResolver para retornar artefatos ou erros controlados."""

    def __init__(self, artifact: DownloadArtifact | None = None, error: str | None = None) -> None:
        """Inicializa o resolvedor falso com artefato ou mensagem de erro."""
        self._artifact = artifact
        self._error = error

    def resolve(self, entry: ModEntry, minecraft_version: str, loader: str) -> DownloadArtifact:
        """Retorna o artefato configurado ou lanca ValueError simulado."""
        if self._error is not None:
            raise ValueError(self._error)
        assert self._artifact is not None
        return self._artifact


def _entry(source: str = "modrinth", **overrides: object) -> ModEntry:
    """Constroi uma entrada de mod valida com sobrescritas opcionais."""
    payload: dict[str, object] = {
        "id": "demo",
        "version": "1.0",
        "source": source,
        "download_url": "https://cdn/demo.jar",
        "sha256": SHA_A,
    }
    payload.update(overrides)
    return ModEntry.from_mapping(payload)


def _manifest(*entries: ModEntry) -> ModManifest:
    """Constroi um ModManifest padrao com as entradas informadas."""
    return ModManifest("26.3", "forge", entries)


def test_empty_manifest_prepares_store() -> None:
    """Garante que manifesto vazio prepara o store sem baixar arquivos."""
    store = FakeStore()
    use_case = SyncModsUseCase(FakeLoader(_manifest()), {}, store, FakeDownloader(store, {}))
    result = use_case.execute()
    assert result.ok
    assert result.items == ()
    assert store.prepared
    assert result.skipped == 0
    assert result.downloaded == 0


def test_skip_cached_when_hash_matches() -> None:
    """Valida reaproveitamento de JAR em cache quando o SHA-256 coincide."""
    entry = _entry()
    filename = jar_filename(entry.mod_id, entry.version)
    store = FakeStore()
    store.files[filename] = SHA_A
    artifact = DownloadArtifact("https://cdn/demo.jar", Sha256Digest(SHA_A))
    use_case = SyncModsUseCase(
        FakeLoader(_manifest(entry)),
        {ModSource.MODRINTH: FakeResolver(artifact)},
        store,
        FakeDownloader(store, {}),
    )
    result = use_case.execute()
    assert result.ok
    assert result.items[0].status is ModSyncStatus.SKIPPED_CACHED
    assert result.skipped == 1


def test_missing_hash_after_resolve_is_failure() -> None:
    """Garante falha quando o artefato resolvido nao possui SHA-256."""
    entry = _entry(sha256="")
    filename = jar_filename(entry.mod_id, entry.version)
    store = FakeStore()
    store.files[filename] = SHA_F
    artifact = DownloadArtifact("https://cdn/demo.jar", Sha256Digest(""))
    use_case = SyncModsUseCase(
        FakeLoader(_manifest(entry)),
        {ModSource.MODRINTH: FakeResolver(artifact)},
        store,
        FakeDownloader(store, {}),
    )
    result = use_case.execute()
    assert not result.ok
    assert "sha256 ausente" in result.failures[0].reason


def test_redownload_on_hash_mismatch_then_success() -> None:
    """Valida novo download quando o arquivo em cache diverge do hash esperado."""
    entry = _entry(sha256=SHA_B)
    filename = jar_filename(entry.mod_id, entry.version)
    store = FakeStore()
    store.files[filename] = SHA_A
    artifact = DownloadArtifact("https://cdn/demo.jar", Sha256Digest(SHA_B))
    downloader = FakeDownloader(store, {filename: SHA_B})
    use_case = SyncModsUseCase(
        FakeLoader(_manifest(entry)),
        {ModSource.MODRINTH: FakeResolver(artifact)},
        store,
        downloader,
    )
    result = use_case.execute()
    assert result.ok
    assert result.items[0].status is ModSyncStatus.DOWNLOADED
    assert result.downloaded == 1
    assert downloader.calls == [("https://cdn/demo.jar", filename)]


def test_invalid_hash_after_download_is_failure() -> None:
    """Garante remocao do arquivo e falha quando o hash baixado diverge."""
    entry = _entry(sha256=SHA_C)
    filename = jar_filename(entry.mod_id, entry.version)
    store = FakeStore()
    artifact = DownloadArtifact("https://cdn/demo.jar", Sha256Digest(SHA_C))
    use_case = SyncModsUseCase(
        FakeLoader(_manifest(entry)),
        {ModSource.MODRINTH: FakeResolver(artifact)},
        store,
        FakeDownloader(store, {filename: SHA_D}),
    )
    result = use_case.execute()
    assert not result.ok
    assert filename in store.removed
    assert "sha256 esperado" in result.failures[0].reason


def test_unknown_source_and_resolver_and_download_errors() -> None:
    """Valida registro de falhas para fonte ausente, erro de resolucao e erro de rede."""
    entry = _entry()
    filename = jar_filename(entry.mod_id, entry.version)
    store = FakeStore()
    missing = SyncModsUseCase(FakeLoader(_manifest(entry)), {}, store, FakeDownloader(store, {}))
    missing_result = missing.execute()
    assert "source desconhecida" in missing_result.failures[0].reason

    resolver_error = SyncModsUseCase(
        FakeLoader(_manifest(entry)),
        {ModSource.MODRINTH: FakeResolver(error="nao encontrada")},
        store,
        FakeDownloader(store, {}),
    )
    assert "nao encontrada" in resolver_error.execute().failures[0].reason

    artifact = DownloadArtifact("https://cdn/demo.jar", Sha256Digest(SHA_A))
    download_error = SyncModsUseCase(
        FakeLoader(_manifest(entry)),
        {ModSource.MODRINTH: FakeResolver(artifact)},
        store,
        FakeDownloader(store, {filename: SHA_A}, error="rede"),
    )
    assert download_error.execute().failures[0].reason == "rede"
