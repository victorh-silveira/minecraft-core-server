"""Adaptador para leitura do manifesto de mods em formato JSON."""

import json
from pathlib import Path
from typing import cast

from application.errors import ManifestNotFoundError
from domain.entities.mod_manifest import ModManifest


class JsonManifestLoader:
    """Carrega e valida o manifesto JSON a partir do sistema de arquivos."""

    def __init__(self, path: Path) -> None:
        """Inicializa o carregador com o caminho do arquivo de manifesto."""
        self._path = path

    def load(self) -> ModManifest:
        """Le o arquivo JSON e retorna um ModManifest validado."""
        if not self._path.is_file():
            raise ManifestNotFoundError(str(self._path))
        try:
            payload = json.loads(self._path.read_text(encoding="utf-8"))
        except json.JSONDecodeError as error:
            raise ValueError(f"Manifesto invalido: {error}") from error
        if not isinstance(payload, dict):
            raise ValueError("Manifesto deve ser um objeto JSON")
        return ModManifest.from_mapping(cast(dict[str, object], payload))
