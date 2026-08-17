import shutil
from pathlib import Path

from gates_common import APP_ROOT, REPO_ROOT


def _safe_remove(path: Path) -> None:
    try:
        if path.is_dir():
            shutil.rmtree(path)
            print(f"Removido diretorio: {path}")
        elif path.is_file():
            path.unlink()
            print(f"Removido arquivo: {path}")
    except OSError as error:
        print(f"Erro ao remover {path}: {error}")


def stage_clean() -> None:
    print("\n>>> Executando: Limpeza full-stack")
    for path in REPO_ROOT.rglob("__pycache__"):
        if path.is_dir() and "app" in path.parts:
            _safe_remove(path)
    for ext in ("*.pyc", "*.pyo", "*.pyd"):
        for path in APP_ROOT.rglob(ext):
            if path.is_file():
                _safe_remove(path)
    cache_targets = [
        REPO_ROOT / ".pytest_cache",
        REPO_ROOT / ".ruff_cache",
        REPO_ROOT / ".mypy_cache",
        REPO_ROOT / ".tools",
        REPO_ROOT / ".coverage",
        REPO_ROOT / "htmlcov",
        REPO_ROOT / "dist",
        REPO_ROOT / "build",
        APP_ROOT / ".pytest_cache",
        APP_ROOT / ".ruff_cache",
        APP_ROOT / ".mypy_cache",
        APP_ROOT / ".coverage",
        APP_ROOT / "htmlcov",
    ]
    for target in cache_targets:
        if target.exists():
            _safe_remove(target)
    for path in (REPO_ROOT / "infra" / "terraform").rglob(".terraform"):
        if path.is_dir():
            _safe_remove(path)
    logs_dir = APP_ROOT / "runtime" / "logs"
    if logs_dir.is_dir():
        for path in logs_dir.glob("*.log"):
            if path.is_file():
                _safe_remove(path)
    print("[OK] Limpeza concluida (world, manifesto e .env.example preservados).")
