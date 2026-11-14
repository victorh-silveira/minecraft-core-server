"""Enumeracao de fontes suportadas para resolucao de mods."""

from enum import StrEnum


class ModSource(StrEnum):
    """Provedores suportados no manifesto de mods."""

    MODRINTH = "modrinth"
    CURSEFORGE = "curseforge"
