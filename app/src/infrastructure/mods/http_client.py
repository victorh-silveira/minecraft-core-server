import requests


MODRINTH_API = "https://api.modrinth.com/v2"
USER_AGENT = "minecraft-server-sync/1.0"


def api_get(path: str):
    response = requests.get(
        f"{MODRINTH_API}{path}",
        headers={"User-Agent": USER_AGENT},
        timeout=60,
    )
    response.raise_for_status()
    return response.json()


def download_jar(url: str, destination):
    response = requests.get(
        url,
        headers={"User-Agent": USER_AGENT},
        stream=True,
        timeout=120,
    )
    response.raise_for_status()
    destination.parent.mkdir(parents=True, exist_ok=True)
    with destination.open("wb") as handle:
        for chunk in response.iter_content(chunk_size=8192):
            if chunk:
                handle.write(chunk)
