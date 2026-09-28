#!/usr/bin/env python3
import argparse
import http.client
import json
import sys
import urllib.parse
from typing import Any


def motd_text(status: dict[str, Any]) -> str:
    motd = status.get("motd", {})
    if not isinstance(motd, dict):
        return ""
    clean = motd.get("clean", [])
    if isinstance(clean, list):
        return "\n".join(str(line) for line in clean)
    return str(clean)


def query(base_url: str, target: str, timeout: float, user_agent: str) -> dict[str, Any]:
    base = urllib.parse.urlsplit(base_url)
    if base.scheme != "https" or not base.hostname:
        raise ValueError("a API externa deve usar HTTPS")
    encoded_target = urllib.parse.quote(target, safe=":[]")
    path = f"{base.path.rstrip('/')}/{encoded_target}"
    connection = http.client.HTTPSConnection(base.hostname, base.port or 443, timeout=timeout)
    try:
        connection.request("GET", path, headers={"Accept": "application/json", "User-Agent": user_agent})
        response = connection.getresponse()
        if response.status != 200:
            raise ValueError(f"API externa respondeu HTTP {response.status}")
        return json.load(response)
    finally:
        connection.close()


def main() -> int:
    parser = argparse.ArgumentParser()
    parser.add_argument("target")
    parser.add_argument("--base-url", default="https://api.mcsrvstat.us/3")
    parser.add_argument("--timeout", type=float, default=15.0)
    parser.add_argument("--user-agent", default="minecraft-core-server-smoke/1.0")
    parser.add_argument("--expected-ip", default="")
    parser.add_argument("--expected-motd", default="")
    args = parser.parse_args()
    try:
        status = query(args.base_url, args.target, args.timeout, args.user_agent)
        if status.get("online") is not True:
            errors = status.get("debug", {}).get("errors", [])
            raise ValueError(f"servidor externo offline: {errors}")
        resolved_ip = str(status.get("ip", ""))
        if args.expected_ip and resolved_ip != args.expected_ip:
            raise ValueError(f"IP externo inesperado: {resolved_ip}")
        motd = motd_text(status)
        if args.expected_motd and args.expected_motd not in motd:
            raise ValueError(f"MOTD externo inesperado: {motd!r}")
        summary = {
            "target": args.target,
            "ip": resolved_ip,
            "port": status.get("port"),
            "version": status.get("version"),
            "motd": motd,
        }
        print(json.dumps(summary, ensure_ascii=False, separators=(",", ":")))
        return 0
    except (http.client.HTTPException, json.JSONDecodeError, OSError, ValueError) as error:
        print(f"falha no status Minecraft externo: {error}", file=sys.stderr)
        return 1


if __name__ == "__main__":
    raise SystemExit(main())
