import logging
from typing import Protocol

from application.errors import ManifestNotFoundError, SyncFailedError
from application.use_cases.sync_mods import SyncModsResult, SyncModsUseCase
from domain.entities.mod_source import ModSource
from infrastructure.adapters.curseforge_resolver import CurseForgeResolver
from infrastructure.adapters.http_client import RequestsHttpClient
from infrastructure.adapters.json_manifest_loader import JsonManifestLoader
from infrastructure.adapters.local_jar_store import LocalJarStore
from infrastructure.adapters.modrinth_resolver import ModrinthResolver
from infrastructure.adapters.requests_downloader import RequestsArtifactDownloader
from infrastructure.config.settings import Settings
from infrastructure.logging.events import log_event
from presentation.logging.setup import configure_logging


class SyncRunner(Protocol):
    def execute(self) -> SyncModsResult:
        raise NotImplementedError


def build_use_case(settings: Settings) -> SyncModsUseCase:
    http = RequestsHttpClient(settings.user_agent)
    store = LocalJarStore(settings.mods_dir)
    return SyncModsUseCase(
        manifest_loader=JsonManifestLoader(settings.manifest_path),
        resolvers={
            ModSource.MODRINTH: ModrinthResolver(http),
            ModSource.CURSEFORGE: CurseForgeResolver(),
        },
        store=store,
        downloader=RequestsArtifactDownloader(http, store),
    )


def _log_items(logger: logging.Logger, result: SyncModsResult) -> None:
    for item in result.items:
        event = f"mods.sync.mod.{item.status.value}"
        log_event(logger, logging.DEBUG, event, mod=item.mod_id.value)


def run(settings: Settings | None = None, use_case: SyncRunner | None = None) -> int:
    resolved = settings or Settings.from_env()
    logger = configure_logging(resolved.log_level)
    log_event(
        logger,
        logging.INFO,
        "mods.sync.run.started",
        manifest=str(resolved.manifest_path),
        mods_dir=str(resolved.mods_dir),
    )
    try:
        result = (use_case or build_use_case(resolved)).execute()
    except ManifestNotFoundError as error:
        log_event(logger, logging.ERROR, "mods.sync.run.failed", reason=str(error))
        return 1
    except (ValueError, SyncFailedError) as error:
        log_event(logger, logging.ERROR, "mods.sync.run.failed", reason=str(error))
        return 1
    _log_items(logger, result)
    for failure in result.failures:
        log_event(logger, logging.ERROR, "mods.sync.mod.failed", mod=failure.mod_id, reason=failure.reason)
    if not result.ok:
        log_event(logger, logging.ERROR, "mods.sync.run.failed", failed=len(result.failures))
        return 1
    log_event(
        logger,
        logging.INFO,
        "mods.sync.run.finished",
        downloaded=result.downloaded,
        skipped=result.skipped,
    )
    return 0


def main() -> int:
    return run()
