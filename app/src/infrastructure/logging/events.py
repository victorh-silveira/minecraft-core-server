"""Emissao de eventos semanticos de log com mascaramento de segredos e URLs."""

import logging
import re
from typing import Any
from urllib.parse import urlparse, urlunparse


_SECRET_MARKERS = ("password", "token", "secret", "api_key")
_URL_RE = re.compile(r"https?://[^\s\"'<>]+", re.IGNORECASE)


def _redact_one(candidate: str) -> str:
    """Mascara a query string de uma URL valida preservando esquema e host."""
    parsed = urlparse(candidate)
    if not parsed.scheme or not parsed.netloc:
        return candidate
    query = "***" if parsed.query else ""
    redacted = parsed._replace(query=query, path=parsed.path or "")
    return urlunparse(redacted)


def redact_url(url: str) -> str:
    """Mascara query strings de todas as URLs presentes em um texto."""
    if "://" not in url:
        return url

    def replace(match: re.Match[str]) -> str:
        raw = match.group(0)
        trimmed = raw.rstrip(".,);]")
        return _redact_one(trimmed) + raw[len(trimmed) :]

    return _URL_RE.sub(replace, url)


def _is_secret(key: str) -> bool:
    """Indica se o nome do campo de log representa dado sensivel."""
    lowered = key.lower()
    return any(marker in lowered for marker in _SECRET_MARKERS)


def _format_value(key: str, value: Any) -> str:
    """Formata e sanitiza o valor de um campo estruturado para exibicao em log."""
    if _is_secret(key):
        return "***"
    text = str(value)
    if key in {"url", "download_url", "host", "reason", "error"} or "://" in text:
        return redact_url(text)
    return text


def log_event(logger: logging.Logger, level: int, event: str, **fields: Any) -> None:
    """Emite um evento estruturado no logger informado com campos sanitizados."""
    extras = " ".join(f"{key}={_format_value(key, value)}" for key, value in sorted(fields.items()))
    message = f"event={event}" if not extras else f"event={event} {extras}"
    exc_info = level <= logging.DEBUG and "error" in fields
    logger.log(level, message, exc_info=exc_info)
