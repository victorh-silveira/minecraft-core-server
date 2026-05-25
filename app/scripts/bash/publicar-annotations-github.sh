#!/usr/bin/env bash
set -euo pipefail

REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../../.." && pwd)"
cd "${REPO_ROOT}"

MODE="${1:-static}"
NAMESPACE="${NAMESPACE:-minecraft-server-prod}"
SUMMARY="${GITHUB_STEP_SUMMARY:-}"
PREFIX="minecraft-server.io/"

if [[ -z "${SUMMARY}" ]]; then
  SUMMARY="$(mktemp)"
  CLEANUP_SUMMARY=1
else
  CLEANUP_SUMMARY=0
fi

export MODE NAMESPACE SUMMARY PREFIX REPO_ROOT

python3 <<'PY'
import json
import os
import subprocess
import sys

try:
    import yaml
except ImportError:
    subprocess.check_call([sys.executable, "-m", "pip", "install", "--quiet", "pyyaml"])
    import yaml

mode = os.environ["MODE"]
namespace = os.environ["NAMESPACE"]
summary_path = os.environ["SUMMARY"]
prefix = os.environ["PREFIX"]
repo_root = os.environ["REPO_ROOT"]

rows: list[tuple[str, str, str, str]] = []


def add_rows(kind: str, name: str, annotations: dict | None) -> None:
    if not annotations:
        return
    for key in sorted(annotations):
        if key.startswith(prefix):
            rows.append((kind, name, key, str(annotations[key])))


def load_static() -> None:
    manifest = subprocess.check_output(
        ["kubectl", "kustomize", os.path.join(repo_root, "infra/kubernetes/overlays/prod")],
        text=True,
    )
    for doc in yaml.safe_load_all(manifest):
        if not isinstance(doc, dict):
            continue
        kind = doc.get("kind") or "?"
        meta = doc.get("metadata") or {}
        name = meta.get("name") or "?"
        add_rows(kind, name, meta.get("annotations"))
        spec = doc.get("spec") or {}
        template = spec.get("template") or {}
        tmeta = template.get("metadata") or {}
        add_rows(f"{kind}/PodTemplate", name, tmeta.get("annotations"))


def load_live() -> None:
    targets = [
        ("namespace", namespace),
        ("statefulset", "mc-server"),
        ("service", "mc-server-game"),
        ("service", "mc-server-rcon"),
        ("pod", "mc-server-0"),
        ("pvc", "mc-data"),
        ("cronjob", "mc-world-backup"),
    ]
    for kind, name in targets:
        try:
            raw = subprocess.check_output(
                [
                    "kubectl",
                    "-n",
                    namespace,
                    "get",
                    kind,
                    name,
                    "-o",
                    "json",
                ],
                text=True,
                stderr=subprocess.DEVNULL,
            )
        except subprocess.CalledProcessError:
            continue
        doc = json.loads(raw)
        meta = doc.get("metadata") or {}
        add_rows(kind, name, meta.get("annotations"))


if mode == "live":
    load_live()
    title = "Annotations minecraft-server.io (cluster AKS)"
    note = "Valores de conectividade e saude refletem o estado atual do cluster."
else:
    load_static()
    title = "Annotations minecraft-server.io (manifestos Kustomize)"
    note = (
        "Valores estaticos do overlay prod. Conectividade e saude dinamicas "
        "aparecem no job CD - Pos-deploy apos release."
    )

with open(summary_path, "a", encoding="utf-8") as out:
    out.write(f"## {title}\n\n")
    out.write(f"{note}\n\n")
    if not rows:
        out.write("_Nenhuma annotation encontrada._\n")
    else:
        out.write("| Recurso | Nome | Chave | Valor |\n")
        out.write("|---------|------|-------|-------|\n")
        for kind, name, key, value in rows:
            safe = value.replace("|", "\\|").replace("\n", " ")
            out.write(f"| {kind} | {name} | `{key}` | {safe} |\n")
        out.write(f"\n**Total:** {len(rows)} chaves `{prefix}`*\n")

highlight_keys = (
    f"{prefix}conectividade-endereco",
    f"{prefix}conectividade-host",
    f"{prefix}saude-tcp-externa",
    f"{prefix}saude-statefulset",
    f"{prefix}atualizado-em",
)

for kind, name, key, value in rows:
    if key in highlight_keys and value not in ("", "pendente"):
        title = f"{kind}/{name}"
        print(f"::notice title={title}::{key}={value}")
PY

if [[ "${CLEANUP_SUMMARY}" -eq 1 ]]; then
  cat "${SUMMARY}"
  rm -f "${SUMMARY}"
fi

echo "[OK] Resumo de annotations publicado (modo ${MODE})."
