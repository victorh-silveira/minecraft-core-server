#!/usr/bin/env bash
set -euo pipefail

REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../../.." && pwd)"
cd "${REPO_ROOT}"

if [[ "$(uname -s)" =~ ^(MINGW|MSYS|CYGWIN) ]]; then
  echo "Execute via WSL: bash app/scripts/bash/run-in-linux-env.sh bash app/scripts/bash/gates-github.sh $*"
  exit 1
fi

TOOLS_DIR="${REPO_ROOT}/.tools"
ACTIONLINT_VERSION="${ACTIONLINT_VERSION:-1.7.7}"

actionlint_bin() {
  if command -v actionlint &>/dev/null; then
    command -v actionlint
    return
  fi
  local cache="${TOOLS_DIR}/actionlint/${ACTIONLINT_VERSION}"
  local bin="${cache}/actionlint"
  if [[ -x "${bin}" ]]; then
    echo "${bin}"
    return
  fi
  mkdir -p "${cache}"
  curl -fsSL https://raw.githubusercontent.com/rhysd/actionlint/main/scripts/download-actionlint.bash | bash -s -- "${ACTIONLINT_VERSION}" "${cache}" >&2
  chmod +x "${bin}"
  echo "${bin}"
}

cmd_lint() {
  echo ">>> GitHub YAML sintaxe"
  python - <<'PY'
from pathlib import Path
import sys
import yaml

errors = []
roots = [Path(".github"), Path(".pre-commit-config.yaml")]
files: list[Path] = []
for root in roots:
    if root.is_file():
        files.append(root)
        continue
    if root.is_dir():
        files.extend(p for p in root.rglob("*") if p.suffix in {".yml", ".yaml"} and p.is_file())
for path in files:
    try:
        list(yaml.safe_load_all(path.read_text(encoding="utf-8")))
    except yaml.YAMLError as exc:
        errors.append(f"{path}: {exc}")
if errors:
    print("\n".join(errors))
    sys.exit(1)
print("[OK] YAML de GitHub Actions e hooks valido")
PY
}

cmd_security() {
  echo ">>> GitHub seguranca (credencial estatica)"
  if grep -R -nE 'AZURE_CREDENTIALS|ARM_CLIENT_SECRET' .github --include='*.yml' --include='*.yaml'; then
    echo "[ERRO] credencial estatica referenciada em YAML"
    exit 1
  fi
  echo "[OK] sem AZURE_CREDENTIALS/ARM_CLIENT_SECRET nos workflows"
}

cmd_test() {
  echo ">>> GitHub testes (jobs CI)"
  python - <<'PY'
from pathlib import Path
import sys
import yaml

data = yaml.safe_load(Path(".github/workflows/ci.yml").read_text(encoding="utf-8"))
jobs = set((data.get("jobs") or {}).keys())
required = {"python", "docker", "kubernetes", "terraform", "github", "scripts"}
missing = sorted(required - jobs)
if missing:
    print(f"[ERRO] jobs CI ausentes: {missing}")
    sys.exit(1)
print("[OK] jobs da matriz CI presentes")
PY
}

cmd_validate() {
  local bin
  bin="$(actionlint_bin)"
  echo ">>> actionlint"
  "${bin}"
}

cmd_build() {
  echo ">>> GitHub build (actions locais)"
  python - <<'PY'
from pathlib import Path
import re
import sys

root = Path(".")
missing = []
pattern = re.compile(r"uses:\s*[\"']?\./(\.github/actions/[^\"'\s]+)")
for path in Path(".github").rglob("*.yml"):
    text = path.read_text(encoding="utf-8")
    for match in pattern.finditer(text):
        rel = match.group(1).rstrip("/")
        action = root / rel / "action.yml"
        if not action.is_file():
            missing.append(f"{path}: {rel}")
if missing:
    print("\n".join(missing))
    sys.exit(1)
print("[OK] composite actions referenciadas existem")
PY
}

main() {
  case "${1:-}" in
    lint) cmd_lint ;;
    security) cmd_security ;;
    test) cmd_test ;;
    validate) cmd_validate ;;
    build) cmd_build ;;
    *)
      echo "Uso: $0 lint|security|test|validate|build"
      exit 1
      ;;
  esac
}

main "$@"
