#!/bin/bash
# Hourly wrapper: check for Rust server update, announce to players, save and perform update
# Assumptions:
# - check_update.sh returns exit code 0 when update available, 1 when up-to-date, 2 on error
# - scripts rust_global_message.py and this send_rcon.py are in the same directory
# - this script is run as root (cron), and 'rust' is the non-root user to run installers

SETUP_DIR="/home/rust/rust_server"
CHECK_SCRIPT="$SETUP_DIR/check_update.sh"
GLOBAL_MSG="$SETUP_DIR/rust_global_message.py"
RCON_SEND="$SETUP_DIR/send_rcon.py"
LOG="/home/rust/rust_server/rust_update_auto.log"
INSTALL1="$SETUP_DIR/1_install_rust.sh"
INSTALL2="$SETUP_DIR/2_install_oxide.sh"
SERVICE_NAME="rust-server"
COUNTDOWN_MIN=10

# Ensure log exists
mkdir -p "$(dirname "$LOG")"
touch "$LOG"

timestamp() { date "+%Y-%m-%d %H:%M:%S"; }

echo "$(timestamp) - starting update_auto check" >> "$LOG"

# run check script
"$CHECK_SCRIPT" > /tmp/check_update_output.txt 2>&1
CHECK_EXIT=$?
cat /tmp/check_update_output.txt >> "$LOG" 2>&1

if [ "$CHECK_EXIT" -ne 0 ]; then
  if [ "$CHECK_EXIT" -eq 1 ]; then
    echo "$(timestamp) - no update available" >> "$LOG"
    exit 0
  else
    echo "$(timestamp) - check_update.sh returned error ($CHECK_EXIT), aborting" >> "$LOG"
    exit 2
  fi
fi

echo "$(timestamp) - update available, proceeding" >> "$LOG"

# function to detect if service is running
is_service_running() {
  # prefer systemctl if available
  if command -v systemctl >/dev/null 2>&1; then
    systemctl is-active --quiet "$SERVICE_NAME"
    return $?
  else
    service "$SERVICE_NAME" status 2>/dev/null | grep -q "running"
    return $?
  fi
}

if is_service_running; then
  echo "$(timestamp) - service $SERVICE_NAME is running: sending countdown messages" >> "$LOG"

  # countdown messages per minute (10 -> 1)
  for ((i=COUNTDOWN_MIN; i>=1; i--)); do
    MSG="<color=red>Server restart in ${i} minutes due to a Rust update</color>"
    # call the python script to announce (run as rust user? script executable by root is fine, but run as rust to keep ownership)
    runuser -l rust -c "cd '$SETUP_DIR' && ./rust_global_message.py \"$MSG\"" >> "$LOG" 2>&1 || echo "$(timestamp) - warning: rust_global_message.py returned non-zero" >> "$LOG"
    # sleep 60 seconds between messages, except after last iteration we continue
    if [ $i -gt 1 ]; then
      sleep 60
    fi
  done

  # final restart message
  runuser -l rust -c "cd '$SETUP_DIR' && ./rust_global_message.py \"<color=red>Restarting server...</color>\"" >> "$LOG" 2>&1 || echo "$(timestamp) - warning: final message failed" >> "$LOG"

  # request server save via RCON
  echo "$(timestamp) - sending server.save via RCON" >> "$LOG"
  runuser -l rust -c "cd '$SETUP_DIR' && ./send_rcon.py server.save" >> "$LOG" 2>&1 || echo "$(timestamp) - warning: send_rcon.py returned non-zero" >> "$LOG"

  # wait 10 seconds to let save finish
  sleep 10

  # stop the service (as root)
  echo "$(timestamp) - stopping service $SERVICE_NAME" >> "$LOG"
  service "$SERVICE_NAME" stop >> "$LOG" 2>&1

  # wait until stopped (timeout 60s)
  TIMEOUT=60
  COUNTER=0
  while is_service_running; do
    sleep 1
    COUNTER=$((COUNTER+1))
    if [ "$COUNTER" -ge "$TIMEOUT" ]; then
      echo "$(timestamp) - service did not stop within $TIMEOUT seconds, continuing anyway" >> "$LOG"
      break
    fi
  done

else
  echo "$(timestamp) - service $SERVICE_NAME is NOT running; proceeding to update without announcements" >> "$LOG"
fi

# Run installers as user 'rust' sequentially
if [ -x "$INSTALL1" ]; then
  echo "$(timestamp) - running $INSTALL1 as user rust" >> "$LOG"
  runuser -l rust -c "cd '$SETUP_DIR' && ./1_install_rust.sh" >> "$LOG" 2>&1
  RC1=$?
  if [ "$RC1" -ne 0 ]; then
    echo "$(timestamp) - ERROR: $INSTALL1 failed with code $RC1" >> "$LOG"
    echo "$(timestamp) - aborting update process" >> "$LOG"
    # optionally try to start service again if it was running before; user didn't request, so we stop here
    exit 3
  fi
else
  echo "$(timestamp) - WARNING: $INSTALL1 not found or not executable" >> "$LOG"
  exit 4
fi

if [ -x "$INSTALL2" ]; then
  echo "$(timestamp) - running $INSTALL2 as user rust" >> "$LOG"
  runuser -l rust -c "cd '$SETUP_DIR' && ./2_install_oxide.sh" >> "$LOG" 2>&1
  RC2=$?
  if [ "$RC2" -ne 0 ]; then
    echo "$(timestamp) - ERROR: $INSTALL2 failed with code $RC2" >> "$LOG"
    echo "$(timestamp) - aborting update process" >> "$LOG"
    exit 5
  fi
else
  echo "$(timestamp) - WARNING: $INSTALL2 not found or not executable" >> "$LOG"
  exit 6
fi

# Start the service as root
echo "$(timestamp) - starting service $SERVICE_NAME" >> "$LOG"
service "$SERVICE_NAME" start >> "$LOG" 2>&1

echo "$(timestamp) - update process finished" >> "$LOG"
exit 0
