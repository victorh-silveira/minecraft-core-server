from collections.abc import Callable
from pathlib import Path
from secrets import randbelow
from time import sleep
from typing import Any, cast

import requests

from application.errors import ArtifactError


Get = Callable[..., Any]
Sleeper = Callable[[float], None]

RETRYABLE_STATUS = frozenset({429, 500, 502, 503, 504})
MAX_ATTEMPTS = 4
BASE_DELAY_SECONDS = 0.25


class RequestsHttpClient:
    def __init__(
        self,
        user_agent: str,
        transport: Get | None = None,
        sleeper: Sleeper | None = None,
        max_attempts: int = MAX_ATTEMPTS,
        base_delay_seconds: float = BASE_DELAY_SECONDS,
    ) -> None:
        self._user_agent = user_agent
        self._get: Get = transport or cast(Get, requests.get)
        self._sleep: Sleeper = sleeper or sleep
        self._max_attempts = max_attempts
        self._base_delay_seconds = base_delay_seconds

    def get_json(self, url: str) -> Any:
        response = self._request(url, stream=False, timeout=60)
        return response.json()

    def download(self, url: str, destination: Path) -> None:
        response = self._request(url, stream=True, timeout=120)
        destination.parent.mkdir(parents=True, exist_ok=True)
        partial = destination.with_name(f"{destination.name}.part")
        try:
            with partial.open("wb") as handle:
                for chunk in response.iter_content(chunk_size=8192):
                    if chunk:
                        handle.write(chunk)
            partial.replace(destination)
        except Exception:
            partial.unlink(missing_ok=True)
            raise

    def _request(self, url: str, *, stream: bool, timeout: int) -> Any:
        last_error: Exception | None = None
        for attempt in range(self._max_attempts):
            try:
                response = self._get(
                    url,
                    headers={"User-Agent": self._user_agent},
                    stream=stream,
                    timeout=timeout,
                )
                status = getattr(response, "status_code", None)
                if status in RETRYABLE_STATUS and attempt + 1 < self._max_attempts:
                    self._close_response(response)
                    self._backoff(attempt)
                    continue
                response.raise_for_status()
                return response
            except requests.RequestException as error:
                last_error = error
                error_response = getattr(error, "response", None)
                status = getattr(error_response, "status_code", None) if error_response is not None else None
                if status in RETRYABLE_STATUS and attempt + 1 < self._max_attempts:
                    self._close_response(error_response)
                    self._backoff(attempt)
                    continue
                raise ArtifactError(str(error)) from error
        raise ArtifactError(str(last_error) if last_error is not None else "falha HTTP")

    def _backoff(self, attempt: int) -> None:
        jitter = (randbelow(1000) / 1000.0) * self._base_delay_seconds
        delay = (self._base_delay_seconds * (2**attempt)) + jitter
        self._sleep(delay)

    @staticmethod
    def _close_response(response: object) -> None:
        close = getattr(response, "close", None)
        if callable(close):
            close()
