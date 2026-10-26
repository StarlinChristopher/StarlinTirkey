import asyncio
import json
import os
import time
import uuid
from pathlib import Path
from urllib.error import HTTPError, URLError
from urllib.request import Request, urlopen

import numpy as np

BUFFER_PATH = Path(os.getenv("BUFFER_PATH", "./buffer"))
INGESTION_URL = os.getenv("INGESTION_URL", "http://node-ingestion:3000/telemetry")
TOKEN_FILE = os.getenv("TELEMETRY_TOKEN_FILE", "/run/secrets/telemetry_api_token")
MAX_BUFFER_FILES = max(1, int(os.getenv("MAX_BUFFER_FILES", "1000")))
MAX_BUFFER_BYTES = max(1024, int(os.getenv("MAX_BUFFER_BYTES", "1073741824")))
UPLOAD_TIMEOUT_SECONDS = max(1, float(os.getenv("UPLOAD_TIMEOUT_SECONDS", "5")))
RETRY_BASE_SECONDS = max(0.1, float(os.getenv("RETRY_BASE_SECONDS", "1")))
DRAIN_INTERVAL_SECONDS = max(1, float(os.getenv("DRAIN_INTERVAL_SECONDS", "15")))
BATCH_INTERVAL_SECONDS = max(1, float(os.getenv("BATCH_INTERVAL_SECONDS", "5")))


def log(level, message, **fields):
    print(json.dumps({"timestamp": time.time(), "level": level, "message": message, **fields}), flush=True)


def load_token():
    try:
        return Path(TOKEN_FILE).read_text(encoding="utf-8").strip()
    except OSError as error:
        log("warning", "telemetry token unavailable", error=str(error))
        return ""


def buffer_files():
    return sorted(
        (item for item in BUFFER_PATH.glob("telematics_*.json") if item.is_file()),
        key=lambda item: item.stat().st_mtime,
    )


def buffer_size_bytes():
    return sum(item.stat().st_size for item in buffer_files() if item.is_file())


def enforce_retention():
    files = buffer_files()
    total_bytes = sum(item.stat().st_size for item in files if item.is_file())
    removed = 0
    while len(files) > MAX_BUFFER_FILES or total_bytes > MAX_BUFFER_BYTES:
        oldest = files.pop(0)
        size = oldest.stat().st_size
        oldest.unlink(missing_ok=True)
        total_bytes -= size
        removed += 1
    if removed:
        log("warning", "buffer retention removed oldest files", removed=removed, files=len(files), bytes=total_bytes)


def write_buffer(payload):
    BUFFER_PATH.mkdir(parents=True, exist_ok=True)
    filename = BUFFER_PATH / f"telematics_{time.time_ns()}_{uuid.uuid4().hex}.json"
    filename.write_text(json.dumps(payload), encoding="utf-8")
    enforce_retention()
    log("info", "telemetry buffered", path=str(filename), files=len(buffer_files()), bytes=buffer_size_bytes())


def upload(payload):
    token = load_token()
    if not token:
        raise RuntimeError("telemetry token is unavailable")
    body = json.dumps(payload).encode("utf-8")
    request = Request(
        INGESTION_URL,
        data=body,
        method="POST",
        headers={
            "Authorization": f"Bearer {token}",
            "Content-Type": "application/json",
        },
    )
    with urlopen(request, timeout=UPLOAD_TIMEOUT_SECONDS) as response:
        if response.status < 200 or response.status >= 300:
            raise RuntimeError(f"upload returned HTTP {response.status}")


def try_upload(payload):
    try:
        upload(payload)
        log("info", "telemetry uploaded")
        return True
    except HTTPError as error:
        if 400 <= error.code < 500 and error.code != 429:
            log("error", "telemetry payload rejected permanently", status=error.code)
            return None
        log("warning", "telemetry upload failed", status=error.code)
        return False
    except (URLError, OSError, RuntimeError, ValueError) as error:
        log("warning", "telemetry upload failed", error=str(error))
        return False


def drain_buffer():
    uploaded = 0
    for filename in buffer_files():
        try:
            payload = json.loads(filename.read_text(encoding="utf-8"))
            result = try_upload(payload)
            if result is False:
                break
            filename.unlink(missing_ok=True)
            uploaded += 1
        except (OSError, json.JSONDecodeError) as error:
            log("error", "invalid buffered telemetry file", path=str(filename), error=str(error))
            filename.unlink(missing_ok=True)
    if uploaded:
        log("info", "buffer drained", uploaded=uploaded, remaining=len(buffer_files()), bytes=buffer_size_bytes())
    return uploaded


def build_payload():
    batch = np.random.normal(loc=65.0, scale=10.0, size=100)
    return {
        "sensorId": "fleetcue-telematics",
        "temperature": float(np.mean(batch)),
    }


async def process_telematics_stream():
    BUFFER_PATH.mkdir(parents=True, exist_ok=True)
    log("info", "asynchronous telematics engine initialized", ingestion_url=INGESTION_URL)
    last_drain = 0.0
    while True:
        now = time.monotonic()
        if now - last_drain >= DRAIN_INTERVAL_SECONDS:
            drain_buffer()
            last_drain = now
        payload = build_payload()
        if not try_upload(payload):
            write_buffer(payload)
        await asyncio.sleep(BATCH_INTERVAL_SECONDS)


if __name__ == "__main__":
    asyncio.run(process_telematics_stream())
