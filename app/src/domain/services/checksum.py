"""Servico de dominio para comparacao de integridade SHA-256."""

from domain.entities.identifiers import Sha256Digest


def matches_expected(actual: Sha256Digest, expected: Sha256Digest) -> bool:
    """Verifica se o digest calculado corresponde ao esperado quando presente."""
    if not expected.is_present():
        return False
    return actual == expected
