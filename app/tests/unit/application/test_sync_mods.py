from application.errors import ArtifactError
from application.use_cases.sync_mods import ModSyncStatus, SyncModsUseCase
from domain.entities.download_artifact import DownloadArtifact
from domain.entities.identifiers import Sha256Digest
from domain.entities.mod_entry import ModEntry
from domain.entities.mod_manifest import ModManifest
from domain.entities.mod_source import ModSource
from domain.services.jar_naming import jar_filename


class FakeLoader:
    def __init__(self, manifest: ModManifest) -> None:
        self._manifest = manifest

    def load(self) -> ModManifest:
        return self._manifest


class FakeStore:
    def __init__(self) -> None:
        self.files: dict[str, str] = {}
        self.prepared = False
        self.removed: list[str] = []

    def prepare(self) -> None:
        self.prepared = True

    def exists(self, filename: str) -> bool:
        return filename in self.files

    def digest(self, filename: str) -> Sha256Digest:
        return Sha256Digest(self.files[filename])

    def remove(self, filename: str) -> None:
        self.removed.append(filename)
        self.files.pop(filename, None)


class FakeDownloader:
    def __init__(self, store: FakeStore, payloads: dict[str, str], error: str | None = None) -> None:
        self._store = store
        self._payloads = payloads
        self._error = error
        self.calls: list[tuple[str, str]] = []

    def download(self, url: str, filename: str) -> None:
        self.calls.append((url, filename))
        if self._error is not None:
            raise ArtifactError(self._error)
        self._store.files[filename] = self._payloads[filename]


class FakeResolver:
    def __init__(self, artifact: DownloadArtifact | None = None, error: str | None = None) -> None:
        self._artifact = artifact
        self._error = error

    def resolve(self, entry: ModEntry, minecraft_version: str, loader: str) -> DownloadArtifact:
        if self._error is not None:
            raise ValueError(self._error)
        assert self._artifact is not None
        return self._artifact


def _entry(source: str = "modrinth", **overrides: object) -> ModEntry:
    payload: dict[str, object] = {
        "id": "demo",
        "version": "1.0",
        "source": source,
        "download_url": "https://cdn/demo.jar",
        "sha256": "aa",
    }
    payload.update(overrides)
    return ModEntry.from_mapping(payload)


def _manifest(*entries: ModEntry) -> ModManifest:
    return ModManifest("1.20.6", "fabric", entries)


def test_empty_manifest_prepares_store() -> None:
    store = FakeStore()
    use_case = SyncModsUseCase(FakeLoader(_manifest()), {}, store, FakeDownloader(store, {}))
    result = use_case.execute()
    assert result.ok
    assert result.items == ()
    assert store.prepared
    assert result.skipped == 0
    assert result.downloaded == 0


def test_skip_cached_when_hash_matches() -> None:
    entry = _entry()
    filename = jar_filename(entry.mod_id, entry.version)
    store = FakeStore()
    store.files[filename] = "aa"
    artifact = DownloadArtifact("https://cdn/demo.jar", Sha256Digest("aa"))
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


def test_skip_cached_without_expected_hash() -> None:
    entry = _entry(sha256="")
    filename = jar_filename(entry.mod_id, entry.version)
    store = FakeStore()
    store.files[filename] = "ff"
    artifact = DownloadArtifact("https://cdn/demo.jar", Sha256Digest(""))
    use_case = SyncModsUseCase(
        FakeLoader(_manifest(entry)),
        {ModSource.MODRINTH: FakeResolver(artifact)},
        store,
        FakeDownloader(store, {}),
    )
    result = use_case.execute()
    assert result.items[0].status is ModSyncStatus.SKIPPED_CACHED


def test_redownload_on_hash_mismatch_then_success() -> None:
    entry = _entry(sha256="bb")
    filename = jar_filename(entry.mod_id, entry.version)
    store = FakeStore()
    store.files[filename] = "aa"
    artifact = DownloadArtifact("https://cdn/demo.jar", Sha256Digest("bb"))
    downloader = FakeDownloader(store, {filename: "bb"})
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
    entry = _entry(sha256="cc")
    filename = jar_filename(entry.mod_id, entry.version)
    store = FakeStore()
    artifact = DownloadArtifact("https://cdn/demo.jar", Sha256Digest("cc"))
    use_case = SyncModsUseCase(
        FakeLoader(_manifest(entry)),
        {ModSource.MODRINTH: FakeResolver(artifact)},
        store,
        FakeDownloader(store, {filename: "dd"}),
    )
    result = use_case.execute()
    assert not result.ok
    assert filename in store.removed
    assert "sha256 esperado" in result.failures[0].reason


def test_unknown_source_and_resolver_and_download_errors() -> None:
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

    artifact = DownloadArtifact("https://cdn/demo.jar", Sha256Digest("aa"))
    download_error = SyncModsUseCase(
        FakeLoader(_manifest(entry)),
        {ModSource.MODRINTH: FakeResolver(artifact)},
        store,
        FakeDownloader(store, {filename: "aa"}, error="rede"),
    )
    assert download_error.execute().failures[0].reason == "rede"
