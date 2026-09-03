from collections.abc import Mapping
from dataclasses import dataclass
from enum import StrEnum

from application.errors import ArtifactError
from application.ports.artifact_downloader import ArtifactDownloader
from application.ports.artifact_store import ArtifactStore
from application.ports.manifest_loader import ManifestLoader
from application.ports.mod_resolver import ModResolver
from domain.entities.identifiers import ModId
from domain.entities.mod_entry import ModEntry
from domain.entities.mod_manifest import ModManifest
from domain.entities.mod_source import ModSource
from domain.services.checksum import matches_expected
from domain.services.jar_naming import jar_filename


class ModSyncStatus(StrEnum):
    SKIPPED_CACHED = "skipped_cached"
    DOWNLOADED = "downloaded"


@dataclass(frozen=True)
class ModSyncItem:
    mod_id: ModId
    status: ModSyncStatus


@dataclass(frozen=True)
class ModSyncFailure:
    mod_id: str
    reason: str


@dataclass(frozen=True)
class SyncModsResult:
    items: tuple[ModSyncItem, ...]
    failures: tuple[ModSyncFailure, ...]

    @property
    def ok(self) -> bool:
        return not self.failures

    @property
    def skipped(self) -> int:
        return sum(1 for item in self.items if item.status is ModSyncStatus.SKIPPED_CACHED)

    @property
    def downloaded(self) -> int:
        return sum(1 for item in self.items if item.status is ModSyncStatus.DOWNLOADED)


class SyncModsUseCase:
    def __init__(
        self,
        manifest_loader: ManifestLoader,
        resolvers: Mapping[ModSource, ModResolver],
        store: ArtifactStore,
        downloader: ArtifactDownloader,
    ) -> None:
        self._manifest_loader = manifest_loader
        self._resolvers = resolvers
        self._store = store
        self._downloader = downloader

    def execute(self) -> SyncModsResult:
        manifest = self._manifest_loader.load()
        self._store.prepare()
        items: list[ModSyncItem] = []
        failures: list[ModSyncFailure] = []
        for entry in manifest.entries:
            try:
                items.append(self._sync_one(entry, manifest))
            except (ValueError, ArtifactError) as error:
                failures.append(ModSyncFailure(entry.mod_id.value, str(error)))
        return SyncModsResult(tuple(items), tuple(failures))

    def _sync_one(self, entry: ModEntry, manifest: ModManifest) -> ModSyncItem:
        filename = jar_filename(entry.mod_id, entry.version)
        resolver = self._resolvers.get(entry.source)
        if resolver is None:
            raise ValueError(f"Mod {entry.mod_id.value}: source desconhecida '{entry.source.value}'")
        artifact = resolver.resolve(entry, manifest.minecraft_version, manifest.loader)
        if not artifact.sha256.is_present():
            raise ValueError(f"Mod {entry.mod_id.value}: sha256 ausente apos resolucao")
        if self._store.exists(filename) and matches_expected(self._store.digest(filename), artifact.sha256):
            return ModSyncItem(entry.mod_id, ModSyncStatus.SKIPPED_CACHED)
        self._downloader.download(artifact.url, filename)
        actual = self._store.digest(filename)
        if actual != artifact.sha256:
            self._store.remove(filename)
            raise ValueError(
                f"Mod {entry.mod_id.value}: sha256 esperado {artifact.sha256.value}, obtido {actual.value}"
            )
        return ModSyncItem(entry.mod_id, ModSyncStatus.DOWNLOADED)
