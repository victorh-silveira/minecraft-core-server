class FakeResponse:
    def __init__(
        self,
        payload: object | None = None,
        chunks: list[bytes] | None = None,
        error: Exception | None = None,
    ) -> None:
        self._payload = payload
        self._chunks = chunks or []
        self._error = error

    def raise_for_status(self) -> None:
        if self._error is not None:
            raise self._error

    def json(self) -> object:
        return self._payload

    def iter_content(self, chunk_size: int) -> object:
        return iter(self._chunks)
