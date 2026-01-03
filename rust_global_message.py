#!/usr/bin/env python3
import sys
import json
import websocket

# ---- Configuration ----
RCON_HOST = "127.0.0.1"
RCON_PORT = 28016
RCON_PASSWORD = "sheFA34DDgry6"
# -----------------------

def main():
    if len(sys.argv) < 2:
        print("Usage: rust_say.py <message>")
        sys.exit(1)

    message = " ".join(sys.argv[1:])

    ws = websocket.create_connection(
        f"ws://{RCON_HOST}:{RCON_PORT}/{RCON_PASSWORD}"
    )

    payload = {
        "Identifier": 1,
        "Message": f"say {message}",
        "Name": "WebRcon"
    }

    ws.send(json.dumps(payload))
    ws.close()

if __name__ == "__main__":
    main()
