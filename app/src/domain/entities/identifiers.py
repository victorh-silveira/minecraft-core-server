from dataclasses import dataclass


@dataclass(frozen=True)
class ModId:
    value: str

    def __post_init__(self) -> None:
        stripped = self.value.strip()
        if not stripped:
            raise ValueError("id do mod e obrigatorio")
        object.__setattr__(self, "value", stripped)


@dataclass(frozen=True)
class ModVersion:
    value: str

    def __post_init__(self) -> None:
        stripped = self.value.strip()
        if not stripped:
            raise ValueError("versao do mod e obrigatoria")
        object.__setattr__(self, "value", stripped)


@dataclass(frozen=True)
class Sha256Digest:
    value: str

    def __post_init__(self) -> None:
        normalized = self.value.strip().lower()
        if normalized:
            if any(char not in "0123456789abcdef" for char in normalized):
                raise ValueError("sha256 deve ser hexadecimal")
            if len(normalized) != 64:
                raise ValueError("sha256 deve ter 64 caracteres hexadecimais")
        object.__setattr__(self, "value", normalized)

    def is_present(self) -> bool:
        return bool(self.value)
