import argparse
import shutil
import subprocess
import sys
from pathlib import Path


REPO_ROOT = Path(__file__).resolve().parent.parent.parent.parent
APP_ROOT = REPO_ROOT / "app"
PYPROJECT = APP_ROOT / "pyproject.toml"
REQUIREMENTS = APP_ROOT / "requirements.txt"


def run_tool(module, args, description, cwd=None):
    print(f"\n>>> Executando: {description}")
    command = [sys.executable, "-m", module] + args
    print(f"Command: {' '.join(command)}")
    try:
        subprocess.run(command, check=True, text=True, cwd=cwd or REPO_ROOT)
        return True
    except subprocess.CalledProcessError as error:
        print(f"Erro durante {description}: {error}")
        sys.exit(error.returncode)


def stage_lint():
    targets = ["app/src/infrastructure/mods", "app/scripts/python", "app/tests"]
    fix_cmd = [sys.executable, "-m", "ruff", "check", "--fix", *targets]
    print(f"\n>>> Executando: Ruff Check (auto-fix)\nCommand: {' '.join(fix_cmd)}")
    subprocess.run(fix_cmd, check=True, text=True, cwd=REPO_ROOT)
    run_tool("ruff", ["check", *targets], "Ruff Check", cwd=REPO_ROOT)
    run_tool("ruff", ["format", *targets], "Ruff Format", cwd=REPO_ROOT)
    run_tool("vulture", ["app"], "Vulture Dead Code Detection", cwd=REPO_ROOT)
    run_tool(
        "pylint",
        [
            "--disable=all",
            "--enable=duplicate-code",
            "--min-similarity-lines=15",
            "app/src/infrastructure/mods/",
            "app/scripts/python/",
        ],
        "Pylint Duplicate Code Detection",
        cwd=REPO_ROOT,
    )
    stage_structure()


def stage_structure(max_lines=300):
    print(f"\n>>> Executando: Verificacao Estrutural (Max {max_lines} linhas)")
    violations = []

    for path in APP_ROOT.rglob("*.py"):
        if ".venv" in path.parts or "venv" in path.parts:
            continue

        with path.open("r", encoding="utf-8") as handle:
            count = len(handle.readlines())
            if count > max_lines:
                violations.append(f"{path.relative_to(REPO_ROOT)}: {count} linhas")

    if violations:
        print("\n[ERRO] Violacao de limite de linhas encontrada:")
        for violation in violations:
            print(f"  - {violation}")
        sys.exit(1)
    print(f"[OK] Todos os arquivos estao abaixo de {max_lines} linhas.")


def stage_test(fail_under=100):
    subprocess.run(
        [sys.executable, "-m", "coverage", "run", "-m", "pytest"],
        check=True,
        text=True,
        cwd=APP_ROOT,
    )
    run_tool("coverage", ["report", f"--fail-under={fail_under}"], f"Coverage report (min {fail_under}%)", cwd=APP_ROOT)


def stage_security():
    ignored_vulns = ["PYSEC-2022-42969"]
    ignore_args = []
    for vuln in ignored_vulns:
        ignore_args.extend(["--ignore-vuln", vuln])

    run_tool(
        "bandit",
        ["-r", "app/scripts/python", "-c", str(PYPROJECT)],
        "Bandit Security Scan",
        cwd=REPO_ROOT,
    )
    run_tool(
        "pip_audit",
        ["-r", str(REQUIREMENTS), *ignore_args],
        "Pip-audit Vulnerability Scan",
        cwd=REPO_ROOT,
    )


def stage_clean():
    print("\n>>> Running: Limpeza de lixo e caches")

    def safe_remove(path: Path):
        try:
            if path.is_dir():
                shutil.rmtree(path)
                print(f"Removido diretorio: {path}")
            else:
                path.unlink()
                print(f"Removido arquivo: {path}")
        except OSError as error:
            print(f"Erro ao remover {path}: {error}")

    for path in REPO_ROOT.rglob("__pycache__"):
        if path.is_dir() and "app" in path.parts:
            safe_remove(path)

    for ext in ("*.pyc", "*.pyo", "*.pyd"):
        for path in APP_ROOT.rglob(ext):
            if path.is_file():
                safe_remove(path)

    for name in (".pytest_cache", ".ruff_cache", ".coverage", "htmlcov", "dist", "build"):
        target = REPO_ROOT / name
        if target.exists():
            safe_remove(target)


def main():
    parser = argparse.ArgumentParser(description="Minecraft Server Quality Gate")
    parser.add_argument(
        "--stage",
        required=True,
        choices=["lint", "pytest", "security", "test", "clean"],
        help="Stage to execute",
    )
    parser.add_argument("--coverage-fail-under", type=int, default=100, help="Minimum coverage percentage")

    args = parser.parse_args()

    if args.stage == "lint":
        stage_lint()
    elif args.stage in ["pytest", "test"]:
        stage_test(args.coverage_fail_under)
    elif args.stage == "security":
        stage_security()
    elif args.stage == "clean":
        stage_clean()

    print("\n[SUCESSO] Estagio concluido com sucesso.")


if __name__ == "__main__":
    main()
