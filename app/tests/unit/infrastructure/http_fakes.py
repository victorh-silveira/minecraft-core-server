class FakeResponse:
    def __init__(
        self,
        payload: object | None = None,
        chunks: list[bytes] | None = None,
        error: Exception | None = None,
        status_code: int = 200,
    ) -> None:
        self._payload = payload
        self._chunks = chunks or []
        self._error = error
        self.status_code = status_code
        self.closed = False

    def raise_for_status(self) -> None:
        if self._error is not None:
            raise self._error
        if self.status_code >= 400:
            raise requests_http_error(self.status_code)

    def json(self) -> object:
        return self._payload

    def iter_content(self, chunk_size: int) -> object:
        return iter(self._chunks)

    def close(self) -> None:
        self.closed = True


def requests_http_error(status_code: int) -> Exception:
    import requests

    response = type("Resp", (), {"status_code": status_code, "close": lambda self: None})()
    error = requests.HTTPError(f"HTTP {status_code}")
    error.response = response
    return error
