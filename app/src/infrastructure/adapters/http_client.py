from collections.abc import Callable
from pathlib import Path
from typing import Any, cast

import requests

from application.errors import ArtifactError


Get = Callable[..., Any]


class RequestsHttpClient:
    def __init__(self, user_agent: str, transport: Get | None = None) -> None:
        self._user_agent = user_agent
        self._get: Get = transport or cast(Get, requests.get)

    def get_json(self, url: str) -> Any:
        try:
            response = self._get(url, headers={"User-Agent": self._user_agent}, timeout=60)
            response.raise_for_status()
            return response.json()
        except requests.RequestException as error:
            raise ArtifactError(str(error)) from error

    def download(self, url: str, destination: Path) -> None:
        try:
            response = self._get(
                url,
                headers={"User-Agent": self._user_agent},
                stream=True,
                timeout=120,
            )
            response.raise_for_status()
        except requests.RequestException as error:
            raise ArtifactError(str(error)) from error
        destination.parent.mkdir(parents=True, exist_ok=True)
        with destination.open("wb") as handle:
            for chunk in response.iter_content(chunk_size=8192):
                if chunk:
                    handle.write(chunk)
