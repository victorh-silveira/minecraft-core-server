"""Objetos de valor para identificadores e checksums de mods."""

from dataclasses import dataclass


@dataclass(frozen=True)
class ModId:
    """Identificador unico de um mod no manifesto."""

    value: str

    def __post_init__(self) -> None:
        """Remove espacos e garante identificador nao vazio."""
        stripped = self.value.strip()
        if not stripped:
            raise ValueError("id do mod e obrigatorio")
        object.__setattr__(self, "value", stripped)


@dataclass(frozen=True)
class ModVersion:
    """Versao declarada de um mod no manifesto."""

    value: str

    def __post_init__(self) -> None:
        """Remove espacos e garante versao nao vazia."""
        stripped = self.value.strip()
        if not stripped:
            raise ValueError("versao do mod e obrigatoria")
        object.__setattr__(self, "value", stripped)


@dataclass(frozen=True)
class Sha256Digest:
    """Hash SHA-256 opcional em formato hexadecimal normalizado."""

    value: str

    def __post_init__(self) -> None:
        """Valida formato hexadecimal de 64 caracteres quando informado."""
        normalized = self.value.strip().lower()
        if normalized:
            if any(char not in "0123456789abcdef" for char in normalized):
                raise ValueError("sha256 deve ser hexadecimal")
            if len(normalized) != 64:
                raise ValueError("sha256 deve ter 64 caracteres hexadecimais")
        object.__setattr__(self, "value", normalized)

    def is_present(self) -> bool:
        """Indica se o hash SHA-256 foi preenchido."""
        return bool(self.value)
