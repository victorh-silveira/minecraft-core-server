import os
from dataclasses import dataclass
from pathlib import Path


def apply_dotenv(path: Path) -> None:
    if not path.is_file():
        return
    for raw in path.read_text(encoding="utf-8").splitlines():
        line = raw.strip()
        if not line or line.startswith("#") or "=" not in line:
            continue
        key, _, value = line.partition("=")
        name = key.strip()
        if not name or name in os.environ:
            continue
        os.environ[name] = value.strip().strip("'").strip('"')


def _truthy(value: str) -> bool:
    return value.strip().lower() in {"1", "true", "yes"}


def _path_or_default(raw: str | None, default: Path) -> Path:
    if raw is None or not str(raw).strip():
        return default
    return Path(raw)


@dataclass(frozen=True)
class Settings:
    repo_root: Path
    manifest_path: Path
    mods_dir: Path
    log_level: str
    user_agent: str
    dotenv_path: Path
    disable_dotenv: bool

    @classmethod
    def from_env(cls, environ: dict[str, str] | None = None) -> "Settings":
        env = os.environ if environ is None else environ
        disable_dotenv = _truthy(str(env.get("SYNC_DISABLE_DOTENV", "")))
        repo_root = Path(env.get("REPO_ROOT", Path(__file__).resolve().parents[4])).resolve()
        dotenv_path = Path(env.get("SYNC_DOTENV_PATH", repo_root / ".env"))
        if not disable_dotenv:
            apply_dotenv(dotenv_path)
            env = os.environ if environ is None else environ
            repo_root = Path(env.get("REPO_ROOT", repo_root)).resolve()
        manifest_default = repo_root / "app" / "runtime" / "mods" / "mods-manifest.json"
        mods_default = repo_root / "app" / "runtime" / "mods"
        return cls(
            repo_root=repo_root,
            manifest_path=_path_or_default(env.get("MODS_MANIFEST_PATH"), manifest_default),
            mods_dir=_path_or_default(env.get("MODS_DIR"), mods_default),
            log_level=str(env.get("LOG_LEVEL", "INFO")),
            user_agent=str(env.get("SYNC_USER_AGENT", "minecraft-server-sync/1.0")),
            dotenv_path=dotenv_path,
            disable_dotenv=disable_dotenv,
        )
