import ast
import os
import subprocess
import sys
import tempfile
from pathlib import Path

from gates_common import APP_ROOT, REPO_ROOT, run_tool


PYPROJECT = APP_ROOT / "pyproject.toml"
REQUIREMENTS = APP_ROOT / "requirements.txt"
SRC_ROOT = APP_ROOT / "src"
LINT_TARGETS = ["app/src", "app/tests", "app/scripts", "run.py"]
MYPY_TARGETS = ["src", "tests"]
VULTURE_TARGETS = ["app/src", "app/scripts/operations", "run.py"]
BANDIT_TARGETS = ["app/src", "app/scripts"]
FORBIDDEN_IMPORTS = {
    "domain": {"application", "infrastructure", "presentation"},
    "application": {"infrastructure", "presentation"},
}


def _top_module(name: str) -> str:
    return name.split(".", 1)[0]


def stage_import_boundaries() -> None:
    print("\n>>> Executando: Regras de dependencia hexagonal")
    violations: list[str] = []
    for layer, banned in FORBIDDEN_IMPORTS.items():
        root = SRC_ROOT / layer
        if not root.is_dir():
            continue
        for path in root.rglob("*.py"):
            tree = ast.parse(path.read_text(encoding="utf-8"))
            for node in ast.walk(tree):
                modules: list[str] = []
                if isinstance(node, ast.Import):
                    modules.extend(alias.name for alias in node.names)
                elif isinstance(node, ast.ImportFrom) and node.module:
                    modules.append(node.module)
                for module in modules:
                    if _top_module(module) in banned:
                        relative = path.relative_to(REPO_ROOT)
                        violations.append(f"{relative}: importa {module}")
    if violations:
        print("\n[ERRO] Violacao de dependencia entre camadas:")
        for violation in violations:
            print(f"  - {violation}")
        sys.exit(1)
    print("[OK] domain e application nao importam camadas externas.")


def stage_structure(max_lines: int = 300) -> None:
    print(f"\n>>> Executando: Verificacao estrutural (maximo {max_lines} linhas)")
    violations: list[str] = []
    for path in [*APP_ROOT.rglob("*.py"), REPO_ROOT / "run.py"]:
        if ".venv" in path.parts or "venv" in path.parts:
            continue
        if not path.is_file():
            continue
        with path.open("r", encoding="utf-8") as handle:
            count = len(handle.readlines())
            if count > max_lines:
                try:
                    display = path.relative_to(REPO_ROOT)
                except ValueError:
                    display = path
                violations.append(f"{display}: {count} linhas")
    if violations:
        print("\n[ERRO] Violacao de limite de linhas encontrada:")
        for violation in violations:
            print(f"  - {violation}")
        sys.exit(1)
    print(f"[OK] Todos os arquivos estao abaixo de {max_lines} linhas.")
    stage_import_boundaries()


def stage_lint() -> None:
    fix_cmd = [sys.executable, "-m", "ruff", "check", "--fix", *LINT_TARGETS]
    print(f"\n>>> Executando: Ruff Check (correcao automatica)\nComando: {' '.join(fix_cmd)}")
    subprocess.run(fix_cmd, check=True, text=True, cwd=REPO_ROOT)
    run_tool("ruff", ["check", *LINT_TARGETS], "Ruff Check", cwd=REPO_ROOT)
    run_tool("ruff", ["format", *LINT_TARGETS], "Ruff Format", cwd=REPO_ROOT)
    run_tool("vulture", VULTURE_TARGETS, "Vulture - codigo morto", cwd=REPO_ROOT)
    run_tool(
        "pylint",
        [
            "--disable=all",
            "--enable=duplicate-code",
            "--min-similarity-lines=15",
            "app/src/",
            "app/scripts/operations/",
        ],
        "Pylint - deteccao de codigo duplicado",
        cwd=REPO_ROOT,
    )
    stage_structure()


def stage_validate() -> None:
    run_tool("mypy", ["--config-file", str(PYPROJECT), *MYPY_TARGETS], "mypy --strict", cwd=APP_ROOT)


def stage_test(fail_under: int = 100) -> None:
    env = os.environ.copy()
    env["COVERAGE_FILE"] = str(Path(tempfile.gettempdir()) / "mcs-coverage")
    subprocess.run(
        [sys.executable, "-m", "coverage", "run", "-m", "pytest"],
        check=True,
        text=True,
        cwd=APP_ROOT,
        env=env,
    )
    print(f"\n>>> Executando: Relatorio de cobertura (minimo {fail_under}%)")
    command = [sys.executable, "-m", "coverage", "report", f"--fail-under={fail_under}"]
    print(f"Comando: {' '.join(command)}")
    try:
        subprocess.run(command, check=True, text=True, cwd=str(APP_ROOT), env=env)
    except subprocess.CalledProcessError as error:
        print(f"Erro durante cobertura: {error}")
        sys.exit(error.returncode)


def stage_security() -> None:
    ignored_vulns = ["PYSEC-2022-42969"]
    ignore_args: list[str] = []
    for vuln in ignored_vulns:
        ignore_args.extend(["--ignore-vuln", vuln])
    run_tool("bandit", ["-r", *BANDIT_TARGETS, "-c", str(PYPROJECT)], "Bandit - analise de seguranca", cwd=REPO_ROOT)
    run_tool(
        "pip_audit",
        ["-r", str(REQUIREMENTS), *ignore_args],
        "Pip-audit - vulnerabilidades em dependencias",
        cwd=REPO_ROOT,
    )
