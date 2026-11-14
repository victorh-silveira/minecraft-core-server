"""Servico de dominio para nomeacao deterministica de arquivos JAR."""

from domain.entities.identifiers import ModId, ModVersion


def jar_filename(mod_id: ModId, version: ModVersion) -> str:
    """Gera o nome de arquivo JAR sanitizado a partir do id e versao do mod."""
    safe_version = version.value.replace("/", "_")
    return f"{mod_id.value}-{safe_version}.jar"
