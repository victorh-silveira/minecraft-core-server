import pytest

from domain.entities.download_artifact import DownloadArtifact
from domain.entities.identifiers import ModId, ModVersion, Sha256Digest
from domain.entities.mod_entry import ModEntry
from domain.entities.mod_manifest import ModManifest
from domain.entities.mod_source import ModSource
from domain.services.checksum import matches_expected
from domain.services.jar_naming import jar_filename


SHA_A = "a" * 64
SHA_B = "b" * 64
SHA_C = "c" * 64
SHA_D = "d" * 64


def test_mod_id_and_version_strip_and_reject_empty() -> None:
    assert ModId("  fabric-api ").value == "fabric-api"
    assert ModVersion(" 1.0 ").value == "1.0"
    with pytest.raises(ValueError, match="id do mod"):
        ModId(" ")
    with pytest.raises(ValueError, match="versao"):
        ModVersion("")


def test_sha256_digest_normalizes_and_presence() -> None:
    digest = Sha256Digest(f"  {SHA_A.upper()} ")
    assert digest.value == SHA_A
    assert digest.is_present()
    assert not Sha256Digest("").is_present()
    assert digest == Sha256Digest(SHA_A)
    assert digest != Sha256Digest(SHA_B)
    with pytest.raises(ValueError, match="hexadecimal"):
        Sha256Digest("z" * 64)
    with pytest.raises(ValueError, match="64 caracteres"):
        Sha256Digest("abcd")


def test_download_artifact_requires_url() -> None:
    with pytest.raises(ValueError, match="url de download"):
        DownloadArtifact(" ", Sha256Digest(""))
    artifact = DownloadArtifact(" https://cdn/mod.jar ", Sha256Digest(SHA_A))
    assert artifact.url == "https://cdn/mod.jar"


def test_mod_entry_from_mapping_and_unknown_source() -> None:
    entry = ModEntry.from_mapping(
        {
            "id": "x",
            "version": "1.0",
            "source": "Modrinth",
            "project_slug": " fabric-api ",
            "download_url": " ",
            "sha256": 1,
        }
    )
    assert entry.source is ModSource.MODRINTH
    assert entry.project_slug == "fabric-api"
    assert entry.download_url is None
    assert not entry.sha256.is_present()
    with pytest.raises(ValueError, match="entrada de mod invalida"):
        ModEntry.from_mapping(["nope"])
    with pytest.raises(ValueError, match="id do mod"):
        ModEntry.from_mapping({"id": 1, "version": "1", "source": "modrinth"})
    with pytest.raises(ValueError, match="versao"):
        ModEntry.from_mapping({"id": "x", "version": 1, "source": "modrinth"})
    with pytest.raises(ValueError, match="source e obrigatoria"):
        ModEntry.from_mapping({"id": "x", "version": "1", "source": " "})
    with pytest.raises(ValueError, match="source desconhecida"):
        ModEntry.from_mapping({"id": "x", "version": "1", "source": "other"})


def test_mod_manifest_from_mapping_and_validation() -> None:
    manifest = ModManifest.from_mapping({"mods": []})
    assert manifest.minecraft_version == "1.20.6"
    assert manifest.loader == "fabric"
    assert list(manifest.entries) == []
    with pytest.raises(ValueError, match="minecraft_version invalida"):
        ModManifest.from_mapping({"minecraft_version": " ", "loader": "fabric", "mods": []})
    with pytest.raises(ValueError, match="loader invalido"):
        ModManifest.from_mapping({"minecraft_version": "1.20.6", "loader": " ", "mods": []})
    with pytest.raises(ValueError, match="mods deve ser uma lista"):
        ModManifest.from_mapping({"mods": {}})
    with pytest.raises(ValueError, match="minecraft_version e obrigatoria"):
        ModManifest(" ", "fabric", ())
    with pytest.raises(ValueError, match="loader e obrigatorio"):
        ModManifest("1.20.6", " ", ())


def test_jar_filename_and_checksum() -> None:
    name = jar_filename(ModId("fabric-api"), ModVersion("1.0/2"))
    assert name == "fabric-api-1.0_2.jar"
    expected = Sha256Digest(SHA_A)
    assert matches_expected(Sha256Digest(SHA_A), expected)
    assert not matches_expected(Sha256Digest(SHA_B), expected)
    assert not matches_expected(Sha256Digest(SHA_B), Sha256Digest(""))
