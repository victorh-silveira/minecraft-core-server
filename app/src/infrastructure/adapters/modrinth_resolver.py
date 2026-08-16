from domain.entities.download_artifact import DownloadArtifact
from domain.entities.identifiers import Sha256Digest
from domain.entities.mod_entry import ModEntry
from infrastructure.adapters.http_client import RequestsHttpClient


MODRINTH_API = "https://api.modrinth.com/v2"


class ModrinthResolver:
    def __init__(self, http: RequestsHttpClient) -> None:
        self._http = http

    def resolve(self, entry: ModEntry, minecraft_version: str, loader: str) -> DownloadArtifact:
        if entry.download_url:
            return DownloadArtifact(entry.download_url, entry.sha256)
        if not entry.project_slug:
            raise ValueError(f"Mod {entry.mod_id.value}: informe download_url ou project_slug para source modrinth")
        query = f'/project/{entry.project_slug}/version?game_versions=["{minecraft_version}"]&loaders=["{loader}"]'
        versions = self._http.get_json(f"{MODRINTH_API}{query}")
        if not isinstance(versions, list):
            raise ValueError(f"Mod {entry.mod_id.value}: resposta Modrinth invalida")
        match = next(
            (item for item in versions if isinstance(item, dict) and item.get("version_number") == entry.version.value),
            None,
        )
        if match is None:
            raise ValueError(
                f"Mod {entry.mod_id.value}: versao {entry.version.value} nao encontrada "
                f"no Modrinth para {minecraft_version}/{loader}"
            )
        files = match.get("files")
        if not isinstance(files, list) or not files:
            raise ValueError(f"Mod {entry.mod_id.value}: arquivo Modrinth ausente")
        primary = files[0]
        if not isinstance(primary, dict):
            raise ValueError(f"Mod {entry.mod_id.value}: arquivo Modrinth invalido")
        url = primary.get("url")
        if not isinstance(url, str) or not url.strip():
            raise ValueError(f"Mod {entry.mod_id.value}: url Modrinth ausente")
        sha256 = entry.sha256
        if not sha256.is_present():
            hashes = primary.get("hashes", {})
            if isinstance(hashes, dict):
                raw = hashes.get("sha256") or ""
                if isinstance(raw, str):
                    sha256 = Sha256Digest(raw)
        return DownloadArtifact(url, sha256)
