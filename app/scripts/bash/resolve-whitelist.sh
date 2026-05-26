#!/usr/bin/env bash
set -euo pipefail

UUID_RE='^[0-9a-fA-F]{8}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{12}$'

offline_uuid() {
  python3 -c 'import hashlib,sys,uuid; u=sys.argv[1]; d=("OfflinePlayer:"+u).encode(); m=bytearray(hashlib.md5(d).digest()); m[6]=(m[6]&0x0f)|0x30; m[8]=(m[8]&0x3f)|0x80; print(uuid.UUID(bytes=bytes(m)))' "$1"
}

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
  offline_uuid "${entry}"
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
