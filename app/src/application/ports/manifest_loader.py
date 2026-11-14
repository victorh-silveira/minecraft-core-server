"""Porta para carregamento do manifesto de mods."""

from typing import Protocol

from domain.entities.mod_manifest import ModManifest


class ManifestLoader(Protocol):
    """Contrato para leitura e validacao do manifesto de mods."""

    def load(self) -> ModManifest:
        """Carrega e retorna o manifesto de mods validado."""
        raise NotImplementedError
