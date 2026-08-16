from domain.entities.mod_entry import ModEntry
from infrastructure.adapters.http_client import RequestsHttpClient
from infrastructure.adapters.modrinth_resolver import ModrinthResolver


class RecordingTransport:
    def __init__(self) -> None:
        self.urls: list[str] = []

    def __call__(self, url: str, **_kwargs: object) -> object:
        self.urls.append(url)

        class Response:
            def raise_for_status(self) -> None:
                return None

            def json(self) -> object:
                return [
                    {
                        "version_number": "0.100.8+1.20.6",
                        "files": [
                            {
                                "url": "https://cdn.modrinth.com/data/P7dR8mSH/fabric-api.jar",
                                "hashes": {"sha256": "abc123"},
                            }
                        ],
                    }
                ]

            def iter_content(self, chunk_size: int) -> object:
                return iter(())

        return Response()


def test_modrinth_http_mock_transport() -> None:
    transport = RecordingTransport()
    resolver = ModrinthResolver(RequestsHttpClient("minecraft-server-sync/1.0", transport=transport))
    entry = ModEntry.from_mapping(
        {
            "id": "fabric-api",
            "version": "0.100.8+1.20.6",
            "source": "modrinth",
            "project_slug": "fabric-api",
        }
    )
    artifact = resolver.resolve(entry, "1.20.6", "fabric")
    assert artifact.url.endswith("fabric-api.jar")
    assert artifact.sha256.value == "abc123"
    assert transport.urls
    assert "api.modrinth.com" in transport.urls[0]
