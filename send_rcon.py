#!/usr/bin/env python3
# Sends a raw RCON command via WebRcon (same approach as rust_global_message.py)

import sys
import json
import websocket
import time

# ---- Configuration (match rust_global_message.py) ----
RCON_HOST = "127.0.0.1"
RCON_PORT = 28016
RCON_PASSWORD = "sheFA34DDgry6"
# -------------------------------------------------------

def usage():
    print("Usage: send_rcon.py <command>")
    sys.exit(1)

def main():
    if len(sys.argv) < 2:
        usage()

    command = " ".join(sys.argv[1:])

    try:
        ws = websocket.create_connection(f"ws://{RCON_HOST}:{RCON_PORT}/{RCON_PASSWORD}", timeout=10)
    except Exception as e:
        print(f"ERROR: could not connect to RCON websocket: {e}")
        sys.exit(2)

    payload = {
        "Identifier": 1,
        "Message": command,
        "Name": "WebRcon"
    }

    try:
        ws.send(json.dumps(payload))
        # small delay to ensure server processes it
        time.sleep(0.2)
        ws.close()
    except Exception as e:
        print(f"ERROR: failed to send RCON command: {e}")
        sys.exit(3)

if __name__ == "__main__":
    main()
