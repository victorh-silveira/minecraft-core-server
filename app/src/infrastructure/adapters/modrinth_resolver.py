from domain.entities.download_artifact import DownloadArtifact
from domain.entities.identifiers import Sha256Digest
from domain.entities.mod_entry import ModEntry
from infrastructure.adapters.http_client import RequestsHttpClient
from infrastructure.adapters.modrinth_mapper import map_modrinth_file, pick_primary_file


MODRINTH_API = "https://api.modrinth.com/v2"


class ModrinthResolver:
    def __init__(self, http: RequestsHttpClient) -> None:
        self._http = http

    def resolve(self, entry: ModEntry, minecraft_version: str, loader: str) -> DownloadArtifact:
        if entry.download_url:
            return self._require_sha(DownloadArtifact(entry.download_url, entry.sha256), entry.mod_id.value)
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
        if not isinstance(files, list):
            raise ValueError(f"Mod {entry.mod_id.value}: arquivo Modrinth ausente")
        mapped = map_modrinth_file(pick_primary_file(files, entry.mod_id.value), entry.mod_id.value)
        sha256 = self._merge_sha(entry.sha256, mapped.sha256, entry.mod_id.value)
        return self._require_sha(DownloadArtifact(mapped.url, sha256), entry.mod_id.value)

    @staticmethod
    def _merge_sha(manifest: Sha256Digest, provider: Sha256Digest, mod_id: str) -> Sha256Digest:
        if manifest.is_present() and provider.is_present() and manifest != provider:
            raise ValueError(f"Mod {mod_id}: sha256 manifesto {manifest.value} diverge do Modrinth {provider.value}")
        if manifest.is_present():
            return manifest
        return provider

    @staticmethod
    def _require_sha(artifact: DownloadArtifact, mod_id: str) -> DownloadArtifact:
        if not artifact.sha256.is_present():
            raise ValueError(f"Mod {mod_id}: sha256 ausente apos resolucao")
        return artifact
