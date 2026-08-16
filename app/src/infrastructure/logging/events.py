import logging
from typing import Any
from urllib.parse import urlparse, urlunparse


_SECRET_MARKERS = ("password", "token", "secret", "api_key")


def redact_url(url: str) -> str:
    parsed = urlparse(url)
    if not parsed.scheme or not parsed.netloc:
        return url
    query = "***" if parsed.query else ""
    redacted = parsed._replace(query=query, path=parsed.path or "")
    return urlunparse(redacted)


def _is_secret(key: str) -> bool:
    lowered = key.lower()
    return any(marker in lowered for marker in _SECRET_MARKERS)


def _format_value(key: str, value: Any) -> str:
    if _is_secret(key):
        return "***"
    text = str(value)
    if key in {"url", "download_url", "host"} or "://" in text:
        return redact_url(text)
    return text


def log_event(logger: logging.Logger, level: int, event: str, **fields: Any) -> None:
    extras = " ".join(f"{key}={_format_value(key, value)}" for key, value in sorted(fields.items()))
    message = f"event={event}" if not extras else f"event={event} {extras}"
    exc_info = level <= logging.DEBUG and "error" in fields
    logger.log(level, message, exc_info=exc_info)
