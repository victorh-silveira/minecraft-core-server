class CurseForgeResolver:
    def resolve(self, mod_entry: dict, _minecraft_version: str, _loader: str) -> tuple[str, str]:
        download_url = (mod_entry.get("download_url") or "").strip()
        expected_sha256 = (mod_entry.get("sha256") or "").strip().lower()
        if not download_url:
            raise ValueError(
                f"Mod {mod_entry['id']}: CurseForge requer download_url e CURSEFORGE_API_KEY no ambiente (nao implementado)"
            )
        return download_url, expected_sha256


def resolve_curseforge(mod_entry: dict) -> tuple[str, str]:
    return CurseForgeResolver().resolve(mod_entry, "", "")
