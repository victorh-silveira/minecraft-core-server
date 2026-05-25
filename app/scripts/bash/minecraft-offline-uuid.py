import hashlib
import sys
import uuid


def offline_uuid(username: str) -> str:
    digest = hashlib.md5(f"OfflinePlayer:{username}".encode()).digest()
    data = bytearray(digest)
    data[6] = (data[6] & 0x0F) | 0x30
    data[8] = (data[8] & 0x3F) | 0x80
    return str(uuid.UUID(bytes=bytes(data)))


def main() -> None:
    if len(sys.argv) != 2:
        raise SystemExit(1)
    print(offline_uuid(sys.argv[1]))


if __name__ == "__main__":
    main()
