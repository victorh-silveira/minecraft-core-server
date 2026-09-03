from domain.entities.identifiers import Sha256Digest


def matches_expected(actual: Sha256Digest, expected: Sha256Digest) -> bool:
    if not expected.is_present():
        return False
    return actual == expected
