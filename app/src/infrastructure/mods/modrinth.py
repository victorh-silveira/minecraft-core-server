from infrastructure.mods.http_client import api_get


class ModrinthResolver:
    def resolve(self, mod_entry: dict, minecraft_version: str, loader: str) -> tuple[str, str]:
        download_url = (mod_entry.get("download_url") or "").strip()
        expected_sha256 = (mod_entry.get("sha256") or "").strip().lower()

        if download_url:
            return download_url, expected_sha256

        project_slug = mod_entry.get("project_slug")
        version = mod_entry["version"]
        if not project_slug:
            raise ValueError(f"Mod {mod_entry['id']}: informe download_url ou project_slug para source modrinth")

        versions = api_get(
            f'/project/{project_slug}/version?game_versions=["{minecraft_version}"]&loaders=["{loader}"]'
        )
        match = next(
            (item for item in versions if item.get("version_number") == version),
            None,
        )
        if match is None:
            raise ValueError(
                f"Mod {mod_entry['id']}: versao {version} nao encontrada no Modrinth para {minecraft_version}/{loader}"
            )

        primary = match["files"][0]
        url = primary["url"]
        hashes = primary.get("hashes", {})
        if not expected_sha256:
            expected_sha256 = (hashes.get("sha256") or "").lower()
        return url, expected_sha256


def resolve_modrinth(mod_entry: dict, minecraft_version: str, loader: str) -> tuple[str, str]:
    return ModrinthResolver().resolve(mod_entry, minecraft_version, loader)
