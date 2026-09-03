from domain.entities.download_artifact import DownloadArtifact
from domain.entities.mod_entry import ModEntry


class CurseForgeResolver:
    def resolve(self, entry: ModEntry, _minecraft_version: str, _loader: str) -> DownloadArtifact:
        if not entry.download_url:
            raise ValueError(f"Mod {entry.mod_id.value}: CurseForge requer download_url")
        if not entry.sha256.is_present():
            raise ValueError(f"Mod {entry.mod_id.value}: CurseForge requer sha256")
        return DownloadArtifact(entry.download_url, entry.sha256)
