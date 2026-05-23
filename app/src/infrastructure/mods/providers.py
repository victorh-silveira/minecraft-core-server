from typing import Protocol


class ModResolver(Protocol):
    def resolve(self, mod_entry: dict, minecraft_version: str, loader: str) -> tuple[str, str]: ...
