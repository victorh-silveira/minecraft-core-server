"""Dubles de resposta HTTP reutilizados nos testes unitarios de infraestrutura."""


class FakeResponse:
    """Resposta HTTP simulada para testes de cliente e resolvedores."""

    def __init__(
        self,
        payload: object | None = None,
        chunks: list[bytes] | None = None,
        error: Exception | None = None,
        status_code: int = 200,
    ) -> None:
        """Inicializa payload, chunks de stream, erro simulado e status HTTP."""
        self._payload = payload
        self._chunks = chunks or []
        self._error = error
        self.status_code = status_code
        self.closed = False

    def raise_for_status(self) -> None:
        """Lanca erro simulado ou HTTPError para status de falha."""
        if self._error is not None:
            raise self._error
        if self.status_code >= 400:
            raise requests_http_error(self.status_code)

    def json(self) -> object:
        """Retorna o payload JSON configurado no duble."""
        return self._payload

    def iter_content(self, chunk_size: int) -> object:
        """Itera sobre os blocos de bytes configurados para o download."""
        return iter(self._chunks)

    def close(self) -> None:
        """Marca a resposta simulada como fechada."""
        self.closed = True


def requests_http_error(status_code: int) -> Exception:
    """Cria uma excecao requests.HTTPError associada ao status HTTP informado."""
    import requests

    response = type("Resp", (), {"status_code": status_code, "close": lambda self: None})()
    error = requests.HTTPError(f"HTTP {status_code}")
    error.response = response
    return error
