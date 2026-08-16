import json
from pathlib import Path
from typing import cast

from application.errors import ManifestNotFoundError
from domain.entities.mod_manifest import ModManifest


class JsonManifestLoader:
    def __init__(self, path: Path) -> None:
        self._path = path

    def load(self) -> ModManifest:
        if not self._path.is_file():
            raise ManifestNotFoundError(str(self._path))
        try:
            payload = json.loads(self._path.read_text(encoding="utf-8"))
        except json.JSONDecodeError as error:
            raise ValueError(f"Manifesto invalido: {error}") from error
        if not isinstance(payload, dict):
            raise ValueError("Manifesto deve ser um objeto JSON")
        return ModManifest.from_mapping(cast(dict[str, object], payload))
