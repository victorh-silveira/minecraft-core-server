import json
import logging
from pathlib import Path

import pytest

from application.errors import ArtifactError
from application.use_cases.sync_mods import (
    ModSyncFailure,
    ModSyncItem,
    ModSyncStatus,
    SyncModsResult,
    SyncModsUseCase,
)
from domain.entities.identifiers import ModId
from infrastructure.config.settings import Settings
from presentation.cli import main as exported_main
from presentation.cli.main import build_use_case, main, run
from presentation.logging.setup import configure_logging


class FakeUseCase:
    def __init__(self, result: SyncModsResult | None = None, error: Exception | None = None) -> None:
        self._result = result
        self._error = error

    def execute(self) -> SyncModsResult:
        if self._error is not None:
            raise self._error
        assert self._result is not None
        return self._result


def _settings(tmp_path: Path, manifest: Path | None = None) -> Settings:
    target = manifest or (tmp_path / "mods-manifest.json")
    return Settings(
        repo_root=tmp_path,
        manifest_path=target,
        mods_dir=tmp_path / "mods",
        log_level="DEBUG",
        user_agent="test/1.0",
        dotenv_path=tmp_path / ".env",
        disable_dotenv=True,
    )


def test_run_success_and_empty(tmp_path: Path, caplog: pytest.LogCaptureFixture) -> None:
    caplog.set_level(logging.INFO)
    settings = _settings(tmp_path)
    result = SyncModsResult(
        (
            ModSyncItem(ModId("a"), ModSyncStatus.DOWNLOADED),
            ModSyncItem(ModId("b"), ModSyncStatus.SKIPPED_CACHED),
        ),
        (),
    )
    code = run(settings, FakeUseCase(result))
    assert code == 0
    assert "mods.sync.run.started" in caplog.text
    assert "mods.sync.run.finished" in caplog.text


def test_run_failures_and_errors(tmp_path: Path) -> None:
    settings = _settings(tmp_path)
    failed = SyncModsResult((), (ModSyncFailure("bad", "hash"),))
    assert run(settings, FakeUseCase(failed)) == 1
    from application.errors import ManifestNotFoundError

    assert run(settings, FakeUseCase(error=ManifestNotFoundError("x"))) == 1
    assert run(settings, FakeUseCase(error=ValueError("json"))) == 1
    assert run(settings, FakeUseCase(error=ArtifactError("net"))) == 1


def test_main_with_empty_manifest(tmp_path: Path, monkeypatch: pytest.MonkeyPatch) -> None:
    manifest = tmp_path / "mods-manifest.json"
    manifest.write_text(json.dumps({"mods": []}), encoding="utf-8")
    monkeypatch.setenv("SYNC_DISABLE_DOTENV", "1")
    monkeypatch.setenv("MODS_MANIFEST_PATH", str(manifest))
    monkeypatch.setenv("MODS_DIR", str(tmp_path / "mods"))
    monkeypatch.setenv("LOG_LEVEL", "INFO")
    assert main() == 0
    assert exported_main is main


def test_main_missing_manifest(tmp_path: Path, monkeypatch: pytest.MonkeyPatch) -> None:
    monkeypatch.setenv("SYNC_DISABLE_DOTENV", "1")
    monkeypatch.setenv("MODS_MANIFEST_PATH", str(tmp_path / "missing.json"))
    monkeypatch.setenv("MODS_DIR", str(tmp_path / "mods"))
    assert main() == 1


def test_build_use_case_and_logging(tmp_path: Path) -> None:
    settings = _settings(tmp_path)
    use_case = build_use_case(settings)
    assert isinstance(use_case, SyncModsUseCase)
    logger = configure_logging("NOPE")
    assert logger.name == "mods.sync"
    debug_logger = configure_logging("DEBUG")
    assert debug_logger.name == "mods.sync"


def test_cli_main_module_import() -> None:
    import presentation.cli.__main__ as module

    assert hasattr(module, "main")


def test_package_exports() -> None:
    import application
    import domain
    import infrastructure
    import presentation
    from presentation.logging import configure_logging as exported

    assert application.__name__ == "application"
    assert domain.__name__ == "domain"
    assert infrastructure.__name__ == "infrastructure"
    assert presentation.__name__ == "presentation"
    assert callable(exported)
