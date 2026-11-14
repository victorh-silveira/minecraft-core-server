"""Configuracao inicial do logger da aplicacao."""

import logging


def configure_logging(level_name: str) -> logging.Logger:
    """Configura o logger mods.sync com o nivel informado e silencia bibliotecas HTTP."""
    level = logging.getLevelNamesMapping().get(level_name.upper(), logging.INFO)
    logging.basicConfig(level=level, format="%(levelname)s %(message)s")
    logger = logging.getLogger("mods.sync")
    logger.setLevel(level)
    logging.getLogger("urllib3").setLevel(logging.WARNING)
    logging.getLogger("requests").setLevel(logging.WARNING)
    return logger
