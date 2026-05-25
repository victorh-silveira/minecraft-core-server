#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
UUID_RE='^[0-9a-fA-F]{8}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{12}$'

resolve_entry() {
  local entry="$1"
  entry="${entry#"${entry%%[![:space:]]*}"}"
  entry="${entry%"${entry##*[![:space:]]}"}"
  if [[ -z "${entry}" ]]; then
    return
  fi
  if [[ "${entry}" =~ ${UUID_RE} ]]; then
    printf '%s' "${entry}"
    return
  fi
  python3 "${SCRIPT_DIR}/minecraft-offline-uuid.py" "${entry}"
}

input="${1:-}"
if [[ -z "${input}" ]]; then
  exit 1
fi

IFS=',' read -r -a parts <<< "${input}"
resolved=()
for part in "${parts[@]}"; do
  uuid="$(resolve_entry "${part}")"
  if [[ -n "${uuid}" ]]; then
    resolved+=("${uuid}")
  fi
done

if [[ ${#resolved[@]} -eq 0 ]]; then
  exit 1
fi

(IFS=','; printf '%s' "${resolved[*]}")
