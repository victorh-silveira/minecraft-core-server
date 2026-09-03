import logging
import re
from typing import Any
from urllib.parse import urlparse, urlunparse


_SECRET_MARKERS = ("password", "token", "secret", "api_key")
_URL_RE = re.compile(r"https?://[^\s\"'<>]+", re.IGNORECASE)


def _redact_one(candidate: str) -> str:
    parsed = urlparse(candidate)
    if not parsed.scheme or not parsed.netloc:
        return candidate
    query = "***" if parsed.query else ""
    redacted = parsed._replace(query=query, path=parsed.path or "")
    return urlunparse(redacted)


def redact_url(url: str) -> str:
    if "://" not in url:
        return url

    def replace(match: re.Match[str]) -> str:
        raw = match.group(0)
        trimmed = raw.rstrip(".,);]")
        return _redact_one(trimmed) + raw[len(trimmed) :]

    return _URL_RE.sub(replace, url)


def _is_secret(key: str) -> bool:
    lowered = key.lower()
    return any(marker in lowered for marker in _SECRET_MARKERS)


def _format_value(key: str, value: Any) -> str:
    if _is_secret(key):
        return "***"
    text = str(value)
    if key in {"url", "download_url", "host", "reason", "error"} or "://" in text:
        return redact_url(text)
    return text


def log_event(logger: logging.Logger, level: int, event: str, **fields: Any) -> None:
    extras = " ".join(f"{key}={_format_value(key, value)}" for key, value in sorted(fields.items()))
    message = f"event={event}" if not extras else f"event={event} {extras}"
    exc_info = level <= logging.DEBUG and "error" in fields
    logger.log(level, message, exc_info=exc_info)
