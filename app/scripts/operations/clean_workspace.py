import argparse
import sys
from collections.abc import Callable
from pathlib import Path


sys.path.insert(0, str(Path(__file__).resolve().parent))

import gates_clean
import gates_json
import gates_python
from gates_common import run_bash_gate


AREAS = ("python", "docker", "kubernetes", "terraform", "github", "scripts", "all")
AREA_ORDER = ("python", "docker", "kubernetes", "terraform", "github", "scripts")
STAGES = ("lint", "security", "test", "validate", "build", "clean")
STAGE_ORDER = ("lint", "security", "test", "validate", "build")
BASH_AREAS = {
    "terraform": "gates-terraform.sh",
    "docker": "gates-docker.sh",
    "kubernetes": "gates-kubernetes.sh",
    "github": "gates-github.sh",
    "scripts": "gates-scripts.sh",
}


def _python(stage: str, coverage_fail_under: int) -> None:
    json_handlers: dict[str, Callable[[], None]] = {
        "lint": gates_json.stage_lint,
        "security": gates_json.stage_security,
        "test": gates_json.stage_test,
        "validate": gates_json.stage_validate,
        "build": gates_json.stage_build,
    }
    python_handlers: dict[str, Callable[[], None]] = {
        "lint": gates_python.stage_lint,
        "security": gates_python.stage_security,
        "test": lambda: gates_python.stage_test(coverage_fail_under),
        "validate": gates_python.stage_validate,
        "build": gates_python.stage_build,
    }
    json_handler = json_handlers.get(stage)
    python_handler = python_handlers.get(stage)
    if json_handler is None or python_handler is None:
        print(f"[ERRO] Stage {stage} nao suportado para python")
        sys.exit(1)
    json_handler()
    python_handler()


def _dispatch_area(area: str, stage: str, coverage_fail_under: int) -> None:
    if area == "python":
        _python(stage, coverage_fail_under)
        return
    script = BASH_AREAS.get(area)
    if script is None:
        print(f"[ERRO] Area desconhecida: {area}")
        sys.exit(1)
    run_bash_gate(script, stage)


def main() -> None:
    parser = argparse.ArgumentParser(description="Portao de qualidade do servidor Minecraft")
    parser.add_argument("--stage", required=True, choices=[*STAGES, "pytest"], help="Estagio a executar")
    parser.add_argument("--area", default="all", choices=AREAS, help="Area da matriz")
    parser.add_argument("--coverage-fail-under", type=int, default=100, help="Cobertura minima Python")
    args = parser.parse_args()
    stage = "test" if args.stage == "pytest" else args.stage
    if stage == "clean":
        gates_clean.stage_clean()
        print("\n[SUCESSO] Estagio concluido com sucesso.")
        return
    areas = AREA_ORDER if args.area == "all" and stage in STAGE_ORDER else ((args.area,) if args.area != "all" else ())
    for area in areas:
        print(f"\n========== {area} | {stage} ==========")
        _dispatch_area(area, stage, args.coverage_fail_under)
    print("\n[SUCESSO] Estagio concluido com sucesso.")


if __name__ == "__main__":
    main()
