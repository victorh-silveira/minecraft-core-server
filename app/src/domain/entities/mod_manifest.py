from collections.abc import Mapping, Sequence
from dataclasses import dataclass

from domain.entities.mod_entry import ModEntry


@dataclass(frozen=True)
class ModManifest:
    minecraft_version: str
    loader: str
    mods: tuple[ModEntry, ...]

    def __post_init__(self) -> None:
        version = self.minecraft_version.strip()
        loader = self.loader.strip()
        if not version:
            raise ValueError("minecraft_version e obrigatoria")
        if not loader:
            raise ValueError("loader e obrigatorio")
        object.__setattr__(self, "minecraft_version", version)
        object.__setattr__(self, "loader", loader)

    @classmethod
    def from_mapping(cls, payload: Mapping[str, object]) -> "ModManifest":
        raw_version = payload.get("minecraft_version", "1.20.6")
        if not isinstance(raw_version, str) or not raw_version.strip():
            raise ValueError("minecraft_version invalida")
        raw_loader = payload.get("loader", "fabric")
        if not isinstance(raw_loader, str) or not raw_loader.strip():
            raise ValueError("loader invalido")
        raw_mods = payload.get("mods", [])
        if not isinstance(raw_mods, list):
            raise ValueError("mods deve ser uma lista")
        mods = tuple(ModEntry.from_mapping(item) for item in raw_mods)
        return cls(raw_version, raw_loader, mods)

    @property
    def entries(self) -> Sequence[ModEntry]:
        return self.mods
