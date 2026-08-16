import pytest

from domain.entities.mod_entry import ModEntry
from infrastructure.adapters.http_client import RequestsHttpClient
from infrastructure.adapters.modrinth_resolver import ModrinthResolver
from tests.unit.infrastructure.http_fakes import FakeResponse


def _client(payload: object) -> RequestsHttpClient:
    return RequestsHttpClient("ua", transport=lambda *_a, **_k: FakeResponse(payload=payload))


def test_modrinth_direct_url() -> None:
    entry = ModEntry.from_mapping(
        {
            "id": "x",
            "version": "1.0",
            "source": "modrinth",
            "download_url": "https://cdn/mod.jar",
            "sha256": "AB",
        }
    )
    artifact = ModrinthResolver(_client([])).resolve(entry, "1.20.6", "fabric")
    assert artifact.url == "https://cdn/mod.jar"
    assert artifact.sha256.value == "ab"


def test_modrinth_requires_slug() -> None:
    entry = ModEntry.from_mapping({"id": "x", "version": "1.0", "source": "modrinth"})
    with pytest.raises(ValueError, match="project_slug"):
        ModrinthResolver(_client([])).resolve(entry, "1.20.6", "fabric")


def test_modrinth_invalid_payload_and_missing_version() -> None:
    slug = ModEntry.from_mapping({"id": "x", "version": "1.0.0", "source": "modrinth", "project_slug": "fabric-api"})
    with pytest.raises(ValueError, match="resposta Modrinth invalida"):
        ModrinthResolver(_client({})).resolve(slug, "1.20.6", "fabric")
    with pytest.raises(ValueError, match="nao encontrada"):
        ModrinthResolver(_client([{"version_number": "9.9"}])).resolve(slug, "1.20.6", "fabric")


def test_modrinth_file_errors() -> None:
    slug = ModEntry.from_mapping({"id": "x", "version": "1.0.0", "source": "modrinth", "project_slug": "fabric-api"})
    with pytest.raises(ValueError, match="arquivo Modrinth ausente"):
        ModrinthResolver(_client([{"version_number": "1.0.0", "files": []}])).resolve(slug, "1.20.6", "fabric")
    with pytest.raises(ValueError, match="arquivo Modrinth invalido"):
        ModrinthResolver(_client([{"version_number": "1.0.0", "files": ["x"]}])).resolve(slug, "1.20.6", "fabric")
    with pytest.raises(ValueError, match="url Modrinth ausente"):
        ModrinthResolver(_client([{"version_number": "1.0.0", "files": [{"url": " "}]}])).resolve(
            slug, "1.20.6", "fabric"
        )


def test_modrinth_from_api_hashes() -> None:
    slug = ModEntry.from_mapping({"id": "x", "version": "1.0.0", "source": "modrinth", "project_slug": "fabric-api"})
    payload = [
        {
            "version_number": "1.0.0",
            "files": [{"url": "https://cdn/mod.jar", "hashes": {"sha256": "deadbeef"}}],
        }
    ]
    resolved = ModrinthResolver(_client(payload)).resolve(slug, "1.20.6", "fabric")
    assert resolved.url == "https://cdn/mod.jar"
    assert resolved.sha256.value == "deadbeef"
    with_sha = ModEntry.from_mapping(
        {
            "id": "x",
            "version": "1.0.0",
            "source": "modrinth",
            "project_slug": "fabric-api",
            "sha256": "feedface",
        }
    )
    assert ModrinthResolver(_client(payload)).resolve(with_sha, "1.20.6", "fabric").sha256.value == "feedface"
    empty = [{"version_number": "1.0.0", "files": [{"url": "https://cdn/mod.jar", "hashes": {}}]}]
    assert not ModrinthResolver(_client(empty)).resolve(slug, "1.20.6", "fabric").sha256.is_present()
    odd = [{"version_number": "1.0.0", "files": [{"url": "https://cdn/mod.jar", "hashes": "nope"}]}]
    assert not ModrinthResolver(_client(odd)).resolve(slug, "1.20.6", "fabric").sha256.is_present()
    non_str = [{"version_number": "1.0.0", "files": [{"url": "https://cdn/mod.jar", "hashes": {"sha256": 1}}]}]
    assert not ModrinthResolver(_client(non_str)).resolve(slug, "1.20.6", "fabric").sha256.is_present()
