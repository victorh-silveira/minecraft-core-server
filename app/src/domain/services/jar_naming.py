from domain.entities.identifiers import ModId, ModVersion


def jar_filename(mod_id: ModId, version: ModVersion) -> str:
    safe_version = version.value.replace("/", "_")
    return f"{mod_id.value}-{safe_version}.jar"
