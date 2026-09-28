#!/usr/bin/env python3
import argparse
import json
import socket
import struct
import sys
from typing import Any


def encode_varint(value: int) -> bytes:
    encoded = bytearray()
    while True:
        byte = value & 0x7F
        value >>= 7
        encoded.append(byte | (0x80 if value else 0))
        if not value:
            return bytes(encoded)


def receive_exact(connection: socket.socket, size: int) -> bytes:
    chunks = bytearray()
    while len(chunks) < size:
        chunk = connection.recv(size - len(chunks))
        if not chunk:
            raise ConnectionError("conexao encerrada antes da resposta completa")
        chunks.extend(chunk)
    return bytes(chunks)


def receive_varint(connection: socket.socket) -> int:
    value = 0
    for shift in range(0, 35, 7):
        byte = receive_exact(connection, 1)[0]
        value |= (byte & 0x7F) << shift
        if not byte & 0x80:
            return value
    raise ValueError("VarInt invalido")


def decode_varint(payload: bytes, offset: int = 0) -> tuple[int, int]:
    value = 0
    for shift in range(0, 35, 7):
        byte = payload[offset]
        offset += 1
        value |= (byte & 0x7F) << shift
        if not byte & 0x80:
            return value, offset
    raise ValueError("VarInt invalido")


def flatten_text(component: Any) -> str:
    if isinstance(component, str):
        return component
    if not isinstance(component, dict):
        return ""
    text = str(component.get("text", ""))
    return text + "".join(flatten_text(item) for item in component.get("extra", []))


def query_status(host: str, port: int, timeout: float) -> dict[str, Any]:
    address = host.encode("utf-8")
    handshake = b"\x00" + encode_varint(0) + encode_varint(len(address)) + address
    handshake += struct.pack(">H", port) + b"\x01"
    with socket.create_connection((host, port), timeout=timeout) as connection:
        connection.settimeout(timeout)
        connection.sendall(encode_varint(len(handshake)) + handshake + b"\x01\x00")
        packet = receive_exact(connection, receive_varint(connection))
    packet_id, offset = decode_varint(packet)
    if packet_id != 0:
        raise ValueError(f"pacote de status inesperado: {packet_id}")
    json_size, offset = decode_varint(packet, offset)
    return json.loads(packet[offset : offset + json_size].decode("utf-8"))


def main() -> int:
    parser = argparse.ArgumentParser()
    parser.add_argument("host")
    parser.add_argument("port", type=int)
    parser.add_argument("--timeout", type=float, default=5.0)
    parser.add_argument("--expected-motd", default="")
    args = parser.parse_args()
    try:
        status = query_status(args.host, args.port, args.timeout)
        motd = flatten_text(status.get("description", ""))
        if args.expected_motd and args.expected_motd not in motd:
            raise ValueError(f"MOTD inesperado: {motd!r}")
        summary = {
            "host": args.host,
            "port": args.port,
            "version": status.get("version", {}).get("name"),
            "players_online": status.get("players", {}).get("online"),
            "motd": motd,
        }
        print(json.dumps(summary, ensure_ascii=False, separators=(",", ":")))
        return 0
    except (ConnectionError, json.JSONDecodeError, OSError, ValueError) as error:
        print(f"falha no status Minecraft: {error}", file=sys.stderr)
        return 1


if __name__ == "__main__":
    raise SystemExit(main())
