import argparse
import sys
from pathlib import Path


sys.path.insert(0, str(Path(__file__).resolve().parent))

import gates_clean
import gates_json
import gates_python
from gates_common import run_bash_gate


AREAS = ("python", "terraform", "docker", "kubernetes", "json", "all")
STAGES = ("lint", "validate", "test", "security", "clean")
BASH_AREAS = {
    "terraform": "gates-terraform.sh",
    "docker": "gates-docker.sh",
    "kubernetes": "gates-kubernetes.sh",
}


def _dispatch_area(area: str, stage: str, coverage_fail_under: int) -> None:
    if area == "python":
        if stage == "lint":
            gates_python.stage_lint()
        elif stage == "validate":
            gates_python.stage_validate()
        elif stage == "test":
            gates_python.stage_test(coverage_fail_under)
        elif stage == "security":
            gates_python.stage_security()
        else:
            print(f"[ERRO] Stage {stage} nao suportado para python")
            sys.exit(1)
        return
    if area == "json":
        if stage == "lint":
            gates_json.stage_lint()
        elif stage == "validate":
            gates_json.stage_validate()
        else:
            print(f"[ERRO] Stage {stage} nao suportado para json")
            sys.exit(1)
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
    areas: tuple[str, ...]
    if args.area == "all":
        if stage in {"lint", "validate"}:
            areas = ("python", "terraform", "docker", "kubernetes", "json")
        elif stage in {"test", "security"}:
            areas = ("python", "terraform", "docker", "kubernetes")
        else:
            areas = ()
    else:
        areas = (args.area,)
    for area in areas:
        if area == "json" and stage not in {"lint", "validate"}:
            continue
        print(f"\n========== {area} | {stage} ==========")
        _dispatch_area(area, stage, args.coverage_fail_under)
    print("\n[SUCESSO] Estagio concluido com sucesso.")


if __name__ == "__main__":
    main()
