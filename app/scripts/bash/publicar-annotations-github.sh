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

curated = [
    ("ambiente", "Ambiente"),
    ("conectividade-endereco", "Endereco Minecraft"),
    ("conectividade-host", "Host publico"),
    ("conectividade-loadbalancer", "Load Balancer"),
    ("conectividade-porta", "Porta do jogo"),
    ("saude-tcp-externa", "Porta 25565 (TCP)"),
    ("saude-statefulset", "Replicas prontas"),
    ("saude-logs", "Estado nos logs"),
    ("jogo-versao", "Versao Minecraft"),
    ("jogo-tipo", "Loader"),
    ("azure-dns-fqdn-esperado", "DNS Azure esperado"),
    ("backup-agendamento", "Backup (cron)"),
    ("documentacao-acesso", "Documentacao"),
    ("atualizado-em", "Ultima atualizacao"),
]

source_order = [
    ("service", "mc-server-game"),
    ("statefulset", "mc-server"),
    ("namespace", namespace),
    ("pod", "mc-server-0"),
]

collected: dict[str, tuple[str, str, str]] = {}


def ingest(kind: str, name: str, annotations: dict | None) -> None:
    if not annotations:
        return
    for suffix, _label in curated:
        key = f"{prefix}{suffix}"
        if key not in annotations:
            continue
        if suffix not in collected:
            collected[suffix] = (kind, name, str(annotations[key]))


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
        ingest(kind, name, meta.get("annotations"))


def load_live() -> None:
    for kind, name in source_order:
        try:
            raw = subprocess.check_output(
                ["kubectl", "-n", namespace, "get", kind, name, "-o", "json"],
                text=True,
                stderr=subprocess.DEVNULL,
            )
        except subprocess.CalledProcessError:
            continue
        doc = json.loads(raw)
        meta = doc.get("metadata") or {}
        for suffix, _label in curated:
            key = f"{prefix}{suffix}"
            if key not in (meta.get("annotations") or {}):
                continue
            collected[suffix] = (kind, name, str(meta["annotations"][key]))


load_static()
if mode == "live":
    load_live()
    title = "Servidor Minecraft (resumo operacional)"
    note = "Estado atual do cluster AKS (ate 14 informacoes essenciais)."
else:
    title = "Servidor Minecraft (manifestos)"
    note = "Valores estaticos. Conectividade e saude dinamicas aparecem apos o CD."

with open(summary_path, "a", encoding="utf-8") as out:
    out.write(f"## {title}\n\n")
    out.write(f"{note}\n\n")
    out.write("| Informacao | Valor | Origem |\n")
    out.write("|------------|-------|--------|\n")
    shown = 0
    for suffix, label in curated:
        if suffix not in collected:
            continue
        kind, name, value = collected[suffix]
        safe = value.replace("|", "\\|").replace("\n", " ")
        out.write(f"| {label} | {safe} | {kind}/{name} |\n")
        shown += 1
    if shown == 0:
        out.write("| _nenhum_ | _sem dados_ | _ |\n")
    out.write(f"\n**Total:** {shown} informacoes essenciais.\n")

for suffix, label in curated:
    if suffix not in collected:
        continue
    kind, name, value = collected[suffix]
    if suffix in ("conectividade-endereco", "saude-tcp-externa", "saude-statefulset") and value not in ("", "pendente"):
        print(f"::notice title={label}::{value} ({kind}/{name})")
PY

if [[ "${CLEANUP_SUMMARY}" -eq 1 ]]; then
  cat "${SUMMARY}"
  rm -f "${SUMMARY}"
fi

echo "[OK] Resumo essencial publicado (modo ${MODE})."
