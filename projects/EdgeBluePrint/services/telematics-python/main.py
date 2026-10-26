import asyncio
import json
import os
import time
import numpy as np

BUFFER_PATH = os.getenv("BUFFER_PATH", "./buffer")


async def process_telematics_stream():
    print("[FleetCue] Asynchronous Telematics Engine Initialized.")
    print("[FleetCue] Watch sync marker active.", flush=True)
    while True:
        telematics_batch = np.random.normal(loc=65.0, scale=10.0, size=100)
        avg_speed = float(np.mean(telematics_batch))

        payload = {
            "timestamp": time.time(),
            "average_speed": avg_speed,
            "anomaly_detected": avg_speed > 80.0,
        }
        # Simulate network offline fallback to the buffer
        network_online = False

        if not network_online:
            filename = os.path.join(
                BUFFER_PATH, f"telematics_{int(time.time())}.json"
            )
            with open(filename, "w") as f:
                json.dump(payload, f)
            print(
                f"[FleetCue Offline] Telematics batch buffered to {filename}",
                flush=True,
            )

        await asyncio.sleep(5)


if __name__ == "__main__":
    os.makedirs(BUFFER_PATH, exist_ok=True)
    try:
        os.chown(BUFFER_PATH, os.getuid(), os.getgid())
    except PermissionError:
        pass
    asyncio.run(process_telematics_stream())
