"""Testes unitarios para o cliente HTTP com tentativas e backoff."""

from pathlib import Path

import pytest
import requests

from application.errors import ArtifactError
from infrastructure.adapters.http_client import RequestsHttpClient
from tests.unit.infrastructure.http_fakes import FakeResponse


def test_http_client_errors() -> None:
    """Garante conversao de erros HTTP em ArtifactError no cliente."""
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
    """Valida novas tentativas para codigos HTTP transitorios no JSON e download."""
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
    """Valida nova tentativa quando HTTPError e lancada com status transitorio."""
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
    """Garante tolerancia a respostas sem metodo close durante novas tentativas."""
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
    """Assegura remocao do arquivo parcial quando o download falha no stream."""

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
    """Garante erro explicito quando max_attempts e configurado como zero."""
    client = RequestsHttpClient(
        "ua",
        transport=lambda *_a, **_k: FakeResponse(payload={}),
        sleeper=lambda _delay: None,
        max_attempts=0,
    )
    with pytest.raises(ArtifactError, match="falha HTTP"):
        client.get_json("https://api.example/x")


def test_http_client_retry_exhausted() -> None:
    """Valida erro final apos esgotar todas as tentativas configuradas."""
    client = RequestsHttpClient(
        "ua",
        transport=lambda *_a, **_k: FakeResponse(status_code=503),
        sleeper=lambda _delay: None,
        max_attempts=2,
        base_delay_seconds=0.01,
    )
    with pytest.raises(ArtifactError, match="HTTP 503"):
        client.get_json("https://api.example/x")
