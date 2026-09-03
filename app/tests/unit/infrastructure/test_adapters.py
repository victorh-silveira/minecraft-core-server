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
        sleeper=lambda _delay: None,
        max_attempts=1,
    )
    with pytest.raises(ArtifactError, match="boom"):
        client.get_json("https://api.example/x")
    with pytest.raises(ArtifactError, match="boom"):
        client.download("https://cdn/x", Path("unused"))


def test_http_client_retries_retryable_status(tmp_path: Path) -> None:
    calls = {"n": 0}
    sleeps: list[float] = []
    responses: list[FakeResponse] = []

    def transport(*_a: object, **_k: object) -> FakeResponse:
        calls["n"] += 1
        if calls["n"] < 3:
            response = FakeResponse(status_code=429)
            responses.append(response)
            return response
        response = FakeResponse(payload={"ok": True}, chunks=[b"z"], status_code=200)
        responses.append(response)
        return response

    client = RequestsHttpClient(
        "ua",
        transport=transport,
        sleeper=sleeps.append,
        max_attempts=4,
        base_delay_seconds=0.01,
    )
    assert client.get_json("https://api.example/x") == {"ok": True}
    assert calls["n"] == 3
    assert len(sleeps) == 2
    assert responses[0].closed and responses[1].closed
    assert not responses[2].closed
    destination = tmp_path / "out.jar"
    calls["n"] = 0
    client.download("https://cdn/x", destination)
    assert destination.read_bytes() == b"z"
    assert not destination.with_name("out.jar.part").exists()


def test_http_client_retries_on_raised_http_error() -> None:
    calls = {"n": 0}

    def transport(*_a: object, **_k: object) -> FakeResponse:
        calls["n"] += 1
        if calls["n"] < 2:
            error = requests.HTTPError("temporarily unavailable")
            error.response = type("Resp", (), {"status_code": 503, "close": lambda self: None})()
            raise error
        return FakeResponse(payload={"ok": True})

    client = RequestsHttpClient(
        "ua",
        transport=transport,
        sleeper=lambda _delay: None,
        max_attempts=3,
        base_delay_seconds=0.01,
    )
    assert client.get_json("https://api.example/x") == {"ok": True}
    assert calls["n"] == 2


def test_http_client_retry_without_close_method() -> None:
    calls = {"n": 0}

    class BareResponse:
        status_code = 429

        def raise_for_status(self) -> None:
            raise requests.HTTPError("HTTP 429")

    def transport(*_a: object, **_k: object) -> object:
        calls["n"] += 1
        if calls["n"] < 2:
            return BareResponse()
        return FakeResponse(payload={"ok": True})

    client = RequestsHttpClient(
        "ua",
        transport=transport,
        sleeper=lambda _delay: None,
        max_attempts=3,
        base_delay_seconds=0.01,
    )
    assert client.get_json("https://api.example/x") == {"ok": True}


def test_http_client_download_cleans_partial_on_failure(tmp_path: Path) -> None:
    class BrokenResponse(FakeResponse):
        def iter_content(self, chunk_size: int) -> object:
            raise OSError("disk full")

    client = RequestsHttpClient(
        "ua",
        transport=lambda *_a, **_k: BrokenResponse(chunks=[b"x"], status_code=200),
        sleeper=lambda _delay: None,
        max_attempts=1,
    )
    destination = tmp_path / "broken.jar"
    with pytest.raises(OSError, match="disk full"):
        client.download("https://cdn/x", destination)
    assert not destination.exists()
    assert not destination.with_name("broken.jar.part").exists()


def test_http_client_zero_attempts() -> None:
    client = RequestsHttpClient(
        "ua",
        transport=lambda *_a, **_k: FakeResponse(payload={}),
        sleeper=lambda _delay: None,
        max_attempts=0,
    )
    with pytest.raises(ArtifactError, match="falha HTTP"):
        client.get_json("https://api.example/x")


def test_http_client_retry_exhausted() -> None:
    client = RequestsHttpClient(
        "ua",
        transport=lambda *_a, **_k: FakeResponse(status_code=503),
        sleeper=lambda _delay: None,
        max_attempts=2,
        base_delay_seconds=0.01,
    )
    with pytest.raises(ArtifactError, match="HTTP 503"):
        client.get_json("https://api.example/x")


def test_curseforge_resolver() -> None:
    resolver = CurseForgeResolver()
    with pytest.raises(ValueError, match="CurseForge"):
        resolver.resolve(ModEntry.from_mapping({"id": "x", "version": "1", "source": "curseforge"}), "", "")
    with pytest.raises(ValueError, match="sha256"):
        resolver.resolve(
            ModEntry.from_mapping(
                {
                    "id": "x",
                    "version": "1",
                    "source": "curseforge",
                    "download_url": "https://cdn/x.jar",
                }
            ),
            "",
            "",
        )
    artifact = resolver.resolve(
        ModEntry.from_mapping(
            {
                "id": "x",
                "version": "1",
                "source": "curseforge",
                "download_url": "https://cdn/x.jar",
                "sha256": "a" * 64,
            }
        ),
        "1.20.6",
        "fabric",
    )
    assert artifact.url == "https://cdn/x.jar"
    assert artifact.sha256.value == "a" * 64


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
    embedded = "HTTP 403 for url: https://cdn.example/file.jar?token=leak"
    log_event(logger, logging.ERROR, "mods.sync.run.failed", reason=embedded)
    assert "event=mods.sync.run.started" in caplog.text
    assert "?***" in caplog.text
    assert "hunter2" not in caplog.text
    assert "token=leak" not in caplog.text
    assert redact_url("not-a-url") == "not-a-url"
    assert redact_url("https://cdn.example/file.jar") == "https://cdn.example/file.jar"
    assert "?***" in redact_url(embedded)
    assert "token=leak" not in redact_url(embedded)
    assert redact_url("see http:///odd") == "see http:///odd"
