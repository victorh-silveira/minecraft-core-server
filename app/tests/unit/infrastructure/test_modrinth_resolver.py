import pytest

from domain.entities.mod_entry import ModEntry
from infrastructure.adapters.http_client import RequestsHttpClient
from infrastructure.adapters.modrinth_resolver import ModrinthResolver
from tests.unit.infrastructure.http_fakes import FakeResponse


SHA_AB = "ab" + "0" * 62
SHA_DEAD = "deadbeef" + "0" * 56
SHA_FEED = "feedface" + "0" * 56
SHA_ONE = "1" * 64
SHA_TWO = "2" * 64


def _client(payload: object) -> RequestsHttpClient:
    return RequestsHttpClient("ua", transport=lambda *_a, **_k: FakeResponse(payload=payload))


def test_modrinth_direct_url() -> None:
    entry = ModEntry.from_mapping(
        {
            "id": "x",
            "version": "1.0",
            "source": "modrinth",
            "download_url": "https://cdn/mod.jar",
            "sha256": SHA_AB,
        }
    )
    artifact = ModrinthResolver(_client([])).resolve(entry, "1.20.6", "fabric")
    assert artifact.url == "https://cdn/mod.jar"
    assert artifact.sha256.value == SHA_AB
    missing_sha = ModEntry.from_mapping(
        {
            "id": "x",
            "version": "1.0",
            "source": "modrinth",
            "download_url": "https://cdn/mod.jar",
        }
    )
    with pytest.raises(ValueError, match="sha256 ausente"):
        ModrinthResolver(_client([])).resolve(missing_sha, "1.20.6", "fabric")


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
    with pytest.raises(ValueError, match="arquivo Modrinth ausente"):
        ModrinthResolver(_client([{"version_number": "1.0.0", "files": {}}])).resolve(slug, "1.20.6", "fabric")
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
            "files": [{"url": "https://cdn/mod.jar", "hashes": {"sha256": SHA_DEAD}}],
        }
    ]
    resolved = ModrinthResolver(_client(payload)).resolve(slug, "1.20.6", "fabric")
    assert resolved.url == "https://cdn/mod.jar"
    assert resolved.sha256.value == SHA_DEAD
    with_sha = ModEntry.from_mapping(
        {
            "id": "x",
            "version": "1.0.0",
            "source": "modrinth",
            "project_slug": "fabric-api",
            "sha256": SHA_DEAD,
        }
    )
    assert ModrinthResolver(_client(payload)).resolve(with_sha, "1.20.6", "fabric").sha256.value == SHA_DEAD
    diverge = ModEntry.from_mapping(
        {
            "id": "x",
            "version": "1.0.0",
            "source": "modrinth",
            "project_slug": "fabric-api",
            "sha256": SHA_FEED,
        }
    )
    with pytest.raises(ValueError, match="diverge"):
        ModrinthResolver(_client(payload)).resolve(diverge, "1.20.6", "fabric")
    empty = [{"version_number": "1.0.0", "files": [{"url": "https://cdn/mod.jar", "hashes": {}}]}]
    with pytest.raises(ValueError, match="sha256 ausente"):
        ModrinthResolver(_client(empty)).resolve(slug, "1.20.6", "fabric")
    manifesto_only = ModEntry.from_mapping(
        {
            "id": "x",
            "version": "1.0.0",
            "source": "modrinth",
            "project_slug": "fabric-api",
            "sha256": SHA_FEED,
        }
    )
    assert ModrinthResolver(_client(empty)).resolve(manifesto_only, "1.20.6", "fabric").sha256.value == SHA_FEED
    odd = [{"version_number": "1.0.0", "files": [{"url": "https://cdn/mod.jar", "hashes": "nope"}]}]
    with pytest.raises(ValueError, match="sha256 ausente"):
        ModrinthResolver(_client(odd)).resolve(slug, "1.20.6", "fabric")
    non_str = [{"version_number": "1.0.0", "files": [{"url": "https://cdn/mod.jar", "hashes": {"sha256": 1}}]}]
    with pytest.raises(ValueError, match="sha256 ausente"):
        ModrinthResolver(_client(non_str)).resolve(slug, "1.20.6", "fabric")
    primary_payload = [
        {
            "version_number": "1.0.0",
            "files": [
                {"url": "https://cdn/secondary.jar", "hashes": {"sha256": SHA_ONE}, "primary": False},
                {"url": "https://cdn/primary.jar", "hashes": {"sha256": SHA_TWO}, "primary": True},
            ],
        }
    ]
    primary = ModrinthResolver(_client(primary_payload)).resolve(slug, "1.20.6", "fabric")
    assert primary.url == "https://cdn/primary.jar"
    assert primary.sha256.value == SHA_TWO
