import json
import logging
import os
from pathlib import Path

import pytest
import requests

from application.errors import ArtifactError, ManifestNotFoundError
from domain.entities.mod_entry import ModEntry
from infrastructure.adapters.curseforge_resolver import CurseForgeResolver
from infrastructure.adapters.http_client import RequestsHttpClient
from infrastructure.adapters.json_manifest_loader import JsonManifestLoader
from infrastructure.adapters.local_jar_store import LocalJarStore
from infrastructure.adapters.requests_downloader import RequestsArtifactDownloader
from infrastructure.config.settings import Settings, apply_dotenv
from infrastructure.logging.events import log_event, redact_url
from tests.unit.infrastructure.http_fakes import FakeResponse


def test_json_manifest_loader(tmp_path: Path) -> None:
    missing = JsonManifestLoader(tmp_path / "missing.json")
    with pytest.raises(ManifestNotFoundError):
        missing.load()
    invalid = tmp_path / "bad.json"
    invalid.write_text("{", encoding="utf-8")
    with pytest.raises(ValueError, match="Manifesto invalido"):
        JsonManifestLoader(invalid).load()
    listed = tmp_path / "list.json"
    listed.write_text("[]", encoding="utf-8")
    with pytest.raises(ValueError, match="objeto JSON"):
        JsonManifestLoader(listed).load()
    valid = tmp_path / "ok.json"
    valid.write_text(json.dumps({"mods": []}), encoding="utf-8")
    manifest = JsonManifestLoader(valid).load()
    assert manifest.mods == ()


def test_local_jar_store_and_downloader(tmp_path: Path) -> None:
    store = LocalJarStore(tmp_path)
    store.prepare()
    filename = "demo-1.0.jar"
    assert not store.exists(filename)
    http = RequestsHttpClient("ua", transport=lambda *_a, **_k: FakeResponse(chunks=[b"ab", b"", b"c"]))
    RequestsArtifactDownloader(http, store).download("https://cdn/demo.jar", filename)
    assert store.exists(filename)
    assert store.path_for(filename).read_bytes() == b"abc"
    digest = store.digest(filename)
    assert digest.is_present()
    store.remove(filename)
    assert not store.exists(filename)
    store.remove(filename)


def test_http_client_errors() -> None:
    client = RequestsHttpClient(
        "ua",
        transport=lambda *_a, **_k: FakeResponse(error=requests.HTTPError("boom")),
    )
    with pytest.raises(ArtifactError, match="boom"):
        client.get_json("https://api.example/x")
    with pytest.raises(ArtifactError, match="boom"):
        client.download("https://cdn/x", Path("unused"))


def test_curseforge_resolver() -> None:
    resolver = CurseForgeResolver()
    with pytest.raises(ValueError, match="CurseForge"):
        resolver.resolve(ModEntry.from_mapping({"id": "x", "version": "1", "source": "curseforge"}), "", "")
    artifact = resolver.resolve(
        ModEntry.from_mapping(
            {
                "id": "x",
                "version": "1",
                "source": "curseforge",
                "download_url": "https://cdn/x.jar",
                "sha256": "AA",
            }
        ),
        "1.20.6",
        "fabric",
    )
    assert artifact.url == "https://cdn/x.jar"
    assert artifact.sha256.value == "aa"


def test_apply_dotenv_and_settings(tmp_path: Path, monkeypatch: pytest.MonkeyPatch) -> None:
    missing = tmp_path / "none.env"
    apply_dotenv(missing)
    env_file = tmp_path / ".env"
    env_file.write_text(
        "\n# comment\nBROKEN\nKEEP=one\nKEEP=two\nQUOTED='abc'\nDOUBLE=\"xyz\"\nNEW_VALUE=fromfile\n",
        encoding="utf-8",
    )
    monkeypatch.setenv("KEEP", "existing")
    monkeypatch.delenv("NEW_VALUE", raising=False)
    monkeypatch.delenv("QUOTED", raising=False)
    monkeypatch.delenv("DOUBLE", raising=False)
    apply_dotenv(env_file)
    assert os.environ.get("KEEP") == "existing"
    assert os.environ.get("NEW_VALUE") == "fromfile"
    assert os.environ.get("QUOTED") == "abc"
    assert os.environ.get("DOUBLE") == "xyz"

    monkeypatch.setenv("SYNC_DISABLE_DOTENV", "true")
    monkeypatch.setenv("REPO_ROOT", str(tmp_path))
    monkeypatch.setenv("LOG_LEVEL", "DEBUG")
    settings = Settings.from_env()
    assert settings.disable_dotenv
    assert settings.log_level == "DEBUG"
    assert settings.manifest_path == tmp_path / "app" / "runtime" / "mods" / "mods-manifest.json"

    monkeypatch.setenv("MODS_MANIFEST_PATH", "")
    monkeypatch.setenv("MODS_DIR", "")
    blank = Settings.from_env()
    assert blank.manifest_path == tmp_path / "app" / "runtime" / "mods" / "mods-manifest.json"

    monkeypatch.setenv("SYNC_DISABLE_DOTENV", "0")
    monkeypatch.setenv("SYNC_DOTENV_PATH", str(env_file))
    monkeypatch.setenv("MODS_MANIFEST_PATH", str(tmp_path / "m.json"))
    monkeypatch.setenv("MODS_DIR", str(tmp_path / "mods"))
    monkeypatch.setenv("SYNC_USER_AGENT", "custom/1")
    loaded = Settings.from_env()
    assert loaded.manifest_path == tmp_path / "m.json"
    assert loaded.mods_dir == tmp_path / "mods"
    assert loaded.user_agent == "custom/1"

    custom = Settings.from_env({"SYNC_DISABLE_DOTENV": "yes", "REPO_ROOT": str(tmp_path)})
    assert custom.disable_dotenv
    enabled = Settings.from_env(
        {
            "SYNC_DISABLE_DOTENV": "0",
            "REPO_ROOT": str(tmp_path),
            "SYNC_DOTENV_PATH": str(env_file),
        }
    )
    assert not enabled.disable_dotenv


def test_log_event_redaction(caplog: pytest.LogCaptureFixture) -> None:
    logger = logging.getLogger("test.events")
    caplog.set_level(logging.DEBUG)
    log_event(logger, logging.INFO, "mods.sync.run.started")
    log_event(
        logger,
        logging.INFO,
        "mods.sync.mod.downloaded",
        url="https://cdn.example/file.jar?token=secret",
        rcon_password="hunter2",
        host="mc.local",
    )
    log_event(logger, logging.DEBUG, "mods.sync.run.failed", error="boom")
    assert "event=mods.sync.run.started" in caplog.text
    assert "?***" in caplog.text
    assert "hunter2" not in caplog.text
    assert redact_url("not-a-url") == "not-a-url"
    assert redact_url("https://cdn.example/file.jar") == "https://cdn.example/file.jar"
