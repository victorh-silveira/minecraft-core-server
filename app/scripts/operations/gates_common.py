import subprocess
import sys
from pathlib import Path


REPO_ROOT = Path(__file__).resolve().parent.parent.parent.parent
APP_ROOT = REPO_ROOT / "app"
BASH = APP_ROOT / "scripts" / "bash"
RUN_LINUX = BASH / "run-in-linux-env.sh"


def run_tool(module: str, args: list[str], description: str, cwd: Path | None = None) -> None:
    print(f"\n>>> Executando: {description}")
    command = [sys.executable, "-m", module, *args]
    print(f"Comando: {' '.join(command)}")
    try:
        subprocess.run(command, check=True, text=True, cwd=str(cwd or REPO_ROOT))
    except subprocess.CalledProcessError as error:
        print(f"Erro durante {description}: {error}")
        sys.exit(error.returncode)


def run_bash_gate(script_name: str, stage: str) -> None:
    script = BASH / script_name
    print(f"\n>>> Executando: {script_name} {stage}")
    command = ["bash", str(RUN_LINUX), "bash", str(script), stage]
    print(f"Comando: {' '.join(command)}")
    try:
        subprocess.run(command, check=True, text=True, cwd=str(REPO_ROOT))
    except subprocess.CalledProcessError as error:
        print(f"Erro durante {script_name} {stage}: {error}")
        sys.exit(error.returncode)
