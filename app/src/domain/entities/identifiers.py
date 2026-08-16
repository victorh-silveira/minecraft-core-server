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
        object.__setattr__(self, "value", self.value.strip().lower())

    def is_present(self) -> bool:
        return bool(self.value)
