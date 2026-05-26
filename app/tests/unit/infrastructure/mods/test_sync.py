import json

import infrastructure.mods.http_client as http_mod
import infrastructure.mods.modrinth as modrinth_mod
import infrastructure.mods.paths as paths_mod
import infrastructure.mods.sync as sync_mods
import pytest
import requests


@pytest.fixture
def mods_dir(tmp_path, monkeypatch):
    manifest_dir = tmp_path / "interface" / "mods"
    manifest_dir.mkdir(parents=True)
    monkeypatch.setattr(paths_mod, "MODS_DIR", manifest_dir)
    monkeypatch.setattr(paths_mod, "MANIFEST_PATH", manifest_dir / "mods-manifest.json")
    return manifest_dir


def test_jar_path_sanitizes_version():
    path = sync_mods.jar_path("fabric-api", "1.0/2")
    assert path.name == "fabric-api-1.0_2.jar"


def test_sha256_file(tmp_path):
    sample = tmp_path / "sample.bin"
    sample.write_bytes(b"abc")
    assert sync_mods.sha256_file(sample) == "ba7816bf8f01cfea414140de5dae2223b00361a396177a9cb410ff61f20015ad"


def test_resolve_modrinth_with_download_url():
    entry = {"id": "x", "download_url": "https://example.com/mod.jar", "sha256": "ABC"}
    url, digest = sync_mods.resolve_modrinth(entry, "1.20.6", "fabric")
    assert url == "https://example.com/mod.jar"
    assert digest == "abc"


def test_resolve_modrinth_requires_project_slug():
    entry = {"id": "x", "version": "1.0"}
    with pytest.raises(ValueError, match="project_slug"):
        sync_mods.resolve_modrinth(entry, "1.20.6", "fabric")


def test_resolve_modrinth_version_not_found(monkeypatch):
    entry = {"id": "x", "version": "9.9.9", "project_slug": "fabric-api"}
    monkeypatch.setattr(modrinth_mod, "api_get", lambda _path: [{"version_number": "1.0.0"}])
    with pytest.raises(ValueError, match="nao encontrada"):
        sync_mods.resolve_modrinth(entry, "1.20.6", "fabric")


def test_resolve_modrinth_from_api(monkeypatch):
    entry = {"id": "x", "version": "1.0.0", "project_slug": "fabric-api"}
    monkeypatch.setattr(
        modrinth_mod,
        "api_get",
        lambda _path: [
            {
                "version_number": "1.0.0",
                "files": [{"url": "https://cdn/mod.jar", "hashes": {"sha256": "deadbeef"}}],
            }
        ],
    )
    url, digest = sync_mods.resolve_modrinth(entry, "1.20.6", "fabric")
    assert url == "https://cdn/mod.jar"
    assert digest == "deadbeef"


def test_resolve_curseforge_requires_url():
    with pytest.raises(ValueError, match="CurseForge"):
        sync_mods.resolve_curseforge({"id": "x"})


def test_resolve_curseforge_with_url():
    url, digest = sync_mods.resolve_curseforge({"id": "x", "download_url": "https://example.com/x.jar", "sha256": "AA"})
    assert url == "https://example.com/x.jar"
    assert digest == "aa"


def test_resolve_download_unknown_source():
    with pytest.raises(ValueError, match="desconhecida"):
        sync_mods.resolve_download({"id": "x", "source": "invalid"}, "1.20.6", "fabric")


def test_resolve_download_routes(monkeypatch):
    class FakeModrinth:
        def resolve(self, *_args):
            return "u", "h"

    class FakeCurse:
        def resolve(self, *_args):
            return "c", "d"

    monkeypatch.setattr(
        sync_mods,
        "_RESOLVERS",
        {"modrinth": FakeModrinth(), "curseforge": FakeCurse()},
    )
    assert sync_mods.resolve_download({"id": "x", "source": "modrinth"}, "1.20.6", "fabric") == ("u", "h")
    assert sync_mods.resolve_download({"id": "x", "source": "curseforge"}, "1.20.6", "fabric") == ("c", "d")


def test_api_get(monkeypatch):
    class FakeResponse:
        def raise_for_status(self):
            return None

        def json(self):
            return {"ok": True}

    monkeypatch.setattr(http_mod.requests, "get", lambda *_args, **_kwargs: FakeResponse())
    assert sync_mods.api_get("/test") == {"ok": True}


def test_download_jar(monkeypatch, tmp_path):
    destination = tmp_path / "mod.jar"
    chunks = [b"part1", b"part2"]

    class FakeResponse:
        def raise_for_status(self):
            return None

        def iter_content(self, _chunk_size=8192):
            return iter(chunks)

    monkeypatch.setattr(http_mod.requests, "get", lambda *_args, **_kwargs: FakeResponse())
    sync_mods.download_jar("https://example.com/mod.jar", destination)
    assert destination.read_bytes() == b"part1part2"


def test_sync_mod_already_valid(mods_dir, monkeypatch):
    entry = {"id": "demo", "version": "1.0", "source": "modrinth", "download_url": "https://x/y.jar", "sha256": ""}
    destination = sync_mods.jar_path("demo", "1.0")
    destination.write_bytes(b"cached")
    monkeypatch.setattr(
        sync_mods, "resolve_download", lambda *_args: ("https://x/y.jar", sync_mods.sha256_file(destination))
    )
    assert sync_mods.sync_mod(entry, "1.20.6", "fabric") is True


def test_sync_mod_exists_without_sha256(mods_dir, monkeypatch):
    entry = {"id": "demo", "version": "1.0", "source": "modrinth", "download_url": "https://x/y.jar", "sha256": ""}
    sync_mods.jar_path("demo", "1.0").write_bytes(b"cached")
    monkeypatch.setattr(sync_mods, "resolve_download", lambda *_args: ("https://x/y.jar", ""))
    assert sync_mods.sync_mod(entry, "1.20.6", "fabric") is True


def test_sync_mod_hash_mismatch_redownloads(mods_dir, monkeypatch):
    entry = {
        "id": "demo",
        "version": "1.0",
        "source": "modrinth",
        "download_url": "https://x/y.jar",
        "sha256": "aa" * 32,
    }
    destination = sync_mods.jar_path("demo", "1.0")
    destination.write_bytes(b"old")
    payload = mods_dir / "payload.bin"
    payload.write_bytes(b"new-data")
    expected_new = sync_mods.sha256_file(payload)
    monkeypatch.setattr(sync_mods, "resolve_download", lambda *_args: ("https://x/y.jar", expected_new))

    def fake_download(_url, dest):
        dest.write_bytes(b"new-data")

    monkeypatch.setattr(sync_mods, "download_jar", fake_download)
    assert sync_mods.sync_mod(entry, "1.20.6", "fabric") is True


def test_sync_mod_invalid_hash_after_download(mods_dir, monkeypatch):
    entry = {
        "id": "demo",
        "version": "1.0",
        "source": "modrinth",
        "download_url": "https://x/y.jar",
        "sha256": "cc" * 32,
    }
    monkeypatch.setattr(sync_mods, "resolve_download", lambda *_args: ("https://x/y.jar", "cc" * 32))

    def fake_download(_url, dest):
        dest.write_bytes(b"wrong")

    monkeypatch.setattr(sync_mods, "download_jar", fake_download)
    with pytest.raises(ValueError, match="sha256 esperado"):
        sync_mods.sync_mod(entry, "1.20.6", "fabric")


def test_main_manifest_missing(monkeypatch, tmp_path):
    monkeypatch.setattr(paths_mod, "MANIFEST_PATH", tmp_path / "missing.json")
    with pytest.raises(SystemExit) as exc:
        sync_mods.main()
    assert exc.value.code == 1


def test_main_empty_mods(mods_dir):
    paths_mod.MANIFEST_PATH.write_text(json.dumps({"mods": []}), encoding="utf-8")
    sync_mods.main()


def test_main_with_failure(mods_dir, monkeypatch):
    paths_mod.MANIFEST_PATH.write_text(
        json.dumps({"minecraft_version": "1.20.6", "loader": "fabric", "mods": [{"id": "bad", "version": "1"}]}),
        encoding="utf-8",
    )
    monkeypatch.setattr(
        sync_mods,
        "sync_mod",
        lambda *_args, **_kwargs: (_ for _ in ()).throw(ValueError("fail")),
    )
    with pytest.raises(SystemExit) as exc:
        sync_mods.main()
    assert exc.value.code == 1


def test_main_success(mods_dir, monkeypatch):
    paths_mod.MANIFEST_PATH.write_text(
        json.dumps({"minecraft_version": "1.20.6", "loader": "fabric", "mods": [{"id": "ok", "version": "1"}]}),
        encoding="utf-8",
    )
    monkeypatch.setattr(sync_mods, "sync_mod", lambda *_args, **_kwargs: True)
    sync_mods.main()


def test_main_request_failure(mods_dir, monkeypatch):
    paths_mod.MANIFEST_PATH.write_text(
        json.dumps({"minecraft_version": "1.20.6", "loader": "fabric", "mods": [{"id": "bad", "version": "1"}]}),
        encoding="utf-8",
    )
    monkeypatch.setattr(
        sync_mods,
        "sync_mod",
        lambda *_args, **_kwargs: (_ for _ in ()).throw(requests.RequestException("network")),
    )
    with pytest.raises(SystemExit) as exc:
        sync_mods.main()
    assert exc.value.code == 1


def test_load_manifest(mods_dir):
    payload = {"mods": [{"id": "a"}]}
    paths_mod.MANIFEST_PATH.write_text(json.dumps(payload), encoding="utf-8")
    assert sync_mods.load_manifest() == payload
